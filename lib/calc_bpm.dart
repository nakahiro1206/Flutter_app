import 'dart:io';
import 'dart:math';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/cupertino.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wav/wav.dart';

class BpmAndPower {
  double cosCoef = 0;
  double sinCoef = 0;
  double totalCoef = 0;
  double bpm = 0;

  BpmAndPower(this.bpm);
}

Future<(double?, int?)> calcBPM(String filepath) async {
  final directory = await getApplicationDocumentsDirectory();
  final String outputFile = '${directory.path}/out.wav';
  if (File(outputFile).existsSync()) {
    File(outputFile).deleteSync();
  }
  debugPrint("ffmpeg executed command: -i $filepath -f wav $outputFile");

  final session = await FFmpegKit.execute("-i $filepath -f wav $outputFile");
  final returnCode = await session.getReturnCode();

  if (ReturnCode.isSuccess(returnCode)) {
    // SUCCESS
    debugPrint("mp3 to wav success! $filepath");
    // Read the PCM data from the output file
    // Read a WAV file.
    final wav = await Wav.readFile(outputFile);

    // Look at its metadata.
    debugPrint(wav.format.toString());
    debugPrint(wav.samplesPerSecond.toString());

    // BPM 許容範囲について。
    // bpm/(1 + (許容ずれ)/(曲の長さ)) ~ bpm/(1 - (許容ずれ)/(曲の長さ))
    // 120bpm, 許容ズレを10ms とすれば曲の長さが240s のとき +- 0.005 bpm
    const int samplesInFrame = 512;

    int arrayLength = wav.channels[0].length; // sec * frequency
    double frameRate = wav.samplesPerSecond / samplesInFrame;

    List<double> volumes = [];
    int tmpIdx = 0;
    double tmpSum = 0;
    while (tmpIdx < arrayLength) {
      double left = wav.channels[0][tmpIdx];// -1 to 1.
      double right = wav.channels[1][tmpIdx];
      tmpSum += left*left + right*right;
      if ( (tmpIdx + 1) % samplesInFrame == 0) {
        volumes.add(sqrt(tmpSum / samplesInFrame));
        tmpSum = 0;
      }
      tmpIdx++;
    }
    int frameNum = volumes.length;
    List<double> volumeDiff = [volumes[0]];
    for (int i = 1; i < frameNum; i++) {
      double diff = volumes[i] - volumes[i-1];
      volumeDiff.add((diff > 0)? diff: 0);
    }

    double max = 160;
    double min = 80;
    int stepNum = 80; // modify later.
    List<BpmAndPower> bpmAndPowerList = [for (int i=0; i<stepNum; i++) BpmAndPower(min + (max - min) * i / stepNum)];

    for (final BpmAndPower bpmAndPower in bpmAndPowerList) {
      double f = bpmAndPower.bpm / 60;
      double cosSum = 0;
      double sinSum = 0;
      for (int n = 0; n < frameNum; n++) {
        double hannWindow = 0.5 - 0.5 * cos(2.0 * pi * n / frameNum);
        cosSum += volumeDiff[n] * cos(2.0 * pi * f * n / frameRate) * hannWindow;
        sinSum += volumeDiff[n] * sin(2.0 * pi * f * n / frameRate) * hannWindow;
        // 注意：窓関数を使用しないと端の影響で誤差が出る //
      }
      bpmAndPower.cosCoef = cosSum / frameNum;
      bpmAndPower.sinCoef = sinSum / frameNum;
      bpmAndPower.totalCoef = sqrt(
          bpmAndPower.cosCoef * bpmAndPower.cosCoef +
              bpmAndPower.sinCoef * bpmAndPower.sinCoef);
    }
    bpmAndPowerList.sort((b, a) {return a.totalCoef.compareTo(b.totalCoef);});

    final maxBpmAndPower = bpmAndPowerList[0];
    // 位相差
    double theta = atan2(maxBpmAndPower.sinCoef, maxBpmAndPower.cosCoef);
    if (theta < 0) {
      theta += 2.0 * pi;
    }
    double startTime = theta / (2.0 * pi * maxBpmAndPower.bpm/60);
    debugPrint("Max: freq ${maxBpmAndPower.bpm}, power ${maxBpmAndPower.totalCoef}, startTime $startTime");

    // debugPrint('PCM Data Length: ${pcmData.length}'); // 49038470.
    try {
      // delete PCM file.
      debugPrint("delete wav file! $outputFile");
      await File(outputFile).delete();
    } catch (e) {
      debugPrint("delete wav file failed! $outputFile");
    }

    return (maxBpmAndPower.bpm, (startTime * 1000).toInt());
  } else if (ReturnCode.isCancel(returnCode)) {
    // CANCEL
    debugPrint("mp3 to wav canceled!");
    // error case.
    return (null, null);
  } else {
    // ERROR
    debugPrint("mp3 to wav error!");
    // error case.
    return (null, null);
  }
}
