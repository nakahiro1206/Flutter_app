import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'audio_meta_data.dart' show AudioMetaData, createAudioMetaDataFromFilepathString;

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
  }
}

Future<List<AudioMetaData>> createAudioData() async {
  final Directory directory = await getApplicationDocumentsDirectory();
  final files = directory.listSync();
  final List<String> audioPathList = files
      .where((file) => file.path.endsWith('.mp3'))
      .map((item) => item.path)
      .toList();

  final List<AudioMetaData> audioMetaDataList = [];

  for (final (int idx, String filepath) in audioPathList.indexed) {
    final String title = "undefined_${idx.toString().padLeft(3, "0")}";
    AudioMetaData? audioMetaData = await createAudioMetaDataFromFilepathString(filepath, title);
    if (audioMetaData != null) {
      audioMetaDataList.add(audioMetaData);
    }
  }

  await storeAudioData(audioMetaDataList);
  return audioMetaDataList;
}

Future<List<AudioMetaData>> loadAudioData() async {
  final directory = await getApplicationDocumentsDirectory();
  final jsonFilePath = "${directory.path}/data.json";
  debugPrint(jsonFilePath);

  if (! File(jsonFilePath).existsSync()) {
    debugPrint("$jsonFilePath not existed");
    List<AudioMetaData> audioMetaDataList = await createAudioData(); // create data.json from scratch.
    return audioMetaDataList;
  }

  debugPrint("$jsonFilePath existed");

  final jsonString = File(jsonFilePath).readAsStringSync();
  debugPrint(jsonString);
  final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
  final dynamic audioList = jsonData['audioList']!;

  final List<AudioMetaData> audioMetaDataList = audioList.map<AudioMetaData>((json) => AudioMetaData.fromJson(json)).toList();

  for (final e in audioMetaDataList) {
    debugPrint(e.title);
  }

  return audioMetaDataList;
}

Future<List<AudioMetaData>> loadAudioDataFromScratch() async {
  final directory = await getApplicationDocumentsDirectory();
  final jsonFilePath = "${directory.path}/data.json";
  debugPrint(jsonFilePath);

  if (File(jsonFilePath).existsSync()) {
    await File(jsonFilePath).delete();
  }

  return loadAudioData();
}