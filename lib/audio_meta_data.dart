import 'dart:io';

import 'package:flutter/cupertino.dart';

import 'calc_bpm.dart';

class AudioMetaData {
  double bpm = 0;
  int startTime = 0; // milliseconds
  String title = "";
  String filepath = ""; // applicationDirectory()/{random string}.mp3

  AudioMetaData(this.title, this.bpm, this.startTime, this.filepath);

  // {"audioList":[
  // {"title":"KONKON Beats/白上フブキ(Original)",
  // "bpm":130.0,
  // "startTime":250,
  // "filename":"/data/user/0/com.example.flutter_app/app_flutter/spCTXYciWbIx3jqDjQMTpoIb78KanPGY6ZIeOS3uOUM=.mp3"
  // }]}
  factory AudioMetaData.fromJson(Map<String, dynamic> json) {
    final r = AudioMetaData(
      json['title'] as String, // change to identifier. how to get application directory?
      json['bpm'] as double,
      json['startTime'] as int,
      json['filepath'] as String,
    );
    debugPrint("${r.title}, ${r.filepath}");
    return r;
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'bpm': bpm,
    'startTime': startTime,
    'filepath': filepath
  };
}

Future<AudioMetaData?> createAudioMetaDataFromFilepathString(String filepath, String title) async {
  final (bpm, startTime) = await calcBPM(filepath);
  if (bpm != null && startTime != null) {
    return AudioMetaData(title, bpm, startTime, filepath);
  }
  debugPrint("Failed to calculate bpm of $filepath");
  debugPrint("$filepath is deleted");
  await File(filepath).delete();
  return null;
}