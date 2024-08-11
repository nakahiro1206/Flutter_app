import 'dart:convert';
import 'dart:math';
import 'package:flutter/cupertino.dart';

import 'handle_audio_meta_data.dart';

class CreateRandomString {
  static final Random _random = Random.secure();

  bool isUnique(String convertedString, List<AudioMetaData> audioMetaDataList) {
    for (final audioMetaData in audioMetaDataList) {
      if ( audioMetaData.filepath == convertedString) {
        return false;
      }
    }
    return true;
  }

  String createCryptoRandomFilepath(List<AudioMetaData> audioMetaDataList, String applicationDocumentDirectory) {
    List<int> values = List<int>.generate(32, (i) => _random.nextInt(256));
    String convertedString = "$applicationDocumentDirectory/${base64Url.encode(values)}.mp3";

    while (! isUnique(convertedString, audioMetaDataList)) {
      values = List<int>.generate(32, (i) => _random.nextInt(256));
      convertedString = "$applicationDocumentDirectory/${base64Url.encode(values)}.mp3";
    }

    debugPrint("filepath: $convertedString");
    return convertedString;
  }
}