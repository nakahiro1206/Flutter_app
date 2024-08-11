import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'calc_bpm.dart' show calcBPM;

class AudioMetaData {
  double bpm = 0;
  int startTime = 0; // milliseconds
  String title = "";
  String filepath = ""; // applicationDirectory()/{random string}.mp3

  AudioMetaData(this.title, this.bpm, this.startTime, this.filepath);

  factory AudioMetaData.fromJson(Map<String, dynamic> json) {
    return AudioMetaData(
      json['title'] as String, // change to identifier. how to get application directory?
      json['bpm'] as double,
      json['startTime'] as int,
      json['filepath'] as String
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'bpm': bpm,
    'startTime': startTime,
    'filename': filepath
  };
}

Future<void> storeAudioData(List<AudioMetaData> audioMetaDataList) async {
  final Directory directory = await getApplicationDocumentsDirectory();
  final jsonFilePath = "${directory.path}/data.json";

  if (await directory.exists()) {

    Map<String, dynamic> jsonData = {};
    List<Map> audioList = [];
    for (final AudioMetaData audioMetaData in audioMetaDataList) {
      audioList.add(audioMetaData.toJson());
    }
    jsonData['audioList'] = audioList;

    File(jsonFilePath).writeAsString(jsonEncode(jsonData));
  }
  else {
    debugPrint("${directory.path} does not exist.");
    return;
  }
}

Future<List<AudioMetaData>> createAudioData() async {

  // add lines.
  // outputFile.writeAsStringSync(readLines[j], mode: FileMode.append);

  final Directory directory = await getApplicationDocumentsDirectory();
  final files = directory.listSync();
  final List<String> audioPathList = files
      .where((file) => file.path.endsWith('.mp3'))
      .map((item) => item.path)
      .toList();
  final List<Future<AudioMetaData?>> audioMetaDataListFuture = [];

  for (int idx = 0; idx < audioPathList.length; idx++) {
    String filepath = audioPathList[idx];
    Future<AudioMetaData?> audioMetaData = calcBPM(filepath, "undefined music_$idx}");
    audioMetaDataListFuture.add(audioMetaData);
  }
  final List<AudioMetaData?> audioMetaDataList = await Future.wait(audioMetaDataListFuture);

  // delete if ffmpeg threw error.
  final List<AudioMetaData> audioMetaDataListValidated = [];
  for (int idx = 0; idx < audioPathList.length; idx++) {
    final audioMetaData = audioMetaDataList[idx];
    if (audioMetaData == null) {
      debugPrint("${audioPathList[idx]} is deleted");
      await File(audioPathList[idx]).delete();
    }
    else {
      audioMetaDataListValidated.add(audioMetaData);
    }
  }
  debugPrint(audioMetaDataList.length.toString());
  for (final a in audioMetaDataListValidated) {
    debugPrint("${a.bpm}");
  }

  await storeAudioData(audioMetaDataListValidated);

  return audioMetaDataListValidated;
}

Future<List<AudioMetaData>> loadAudioData() async {
  final directory = await getApplicationDocumentsDirectory();
  final jsonFilePath = "${directory.path}/data.json";

  if (File(jsonFilePath).existsSync()) {
    File(jsonFilePath).deleteSync();
    debugPrint("json deleted.");
  }
  if (! File(jsonFilePath).existsSync()) {
    List<AudioMetaData> audioMetaDataList = await createAudioData(); // create data.json from scratch.
    return audioMetaDataList;
  }

  final jsonString = File(jsonFilePath).readAsStringSync();
  final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
  final dynamic audioList = jsonData['audioList']!;

  final List<AudioMetaData> audioMetaDataList = audioList.map<AudioMetaData>((json) => AudioMetaData.fromJson(json)).toList();

  return audioMetaDataList;
}