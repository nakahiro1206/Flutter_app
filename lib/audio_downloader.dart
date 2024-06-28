import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
// import 'package:permission_handler/permission_handler.dart';

class AudioDownloader {
  final YoutubeExplode yt = YoutubeExplode();

  Future<void> downloadAudio(String url) async {
    try {
      // var status = await Permission.storage.request();
      // if (!status.isGranted) {
      //   throw Exception('Storage permission not granted');
      // }

      // Get video metadata
      var video = await yt.videos.get(url);
      var manifest = await yt.videos.streamsClient.getManifest(video.id);
      var audioStreamInfo = manifest.audioOnly.withHighestBitrate();
      
      // Get the directory to save the file
      final directory = await getApplicationDocumentsDirectory();
      String title = video.title;
      // remove inappropriate symbols
      final RegExp disallowedChars = RegExp(r'[<>:"/\\|?*\x00-\x1F\x7F]');
      title = title.replaceAll(disallowedChars, '');
      title = title.trim();
      final savePath = File('${directory.path}/$title.mp3');
      debugPrint(savePath.path);
      final saveDir = Directory(directory.path);
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      // Download the audio stream
      var stream = yt.videos.streamsClient.get(audioStreamInfo);
      var fileStream = savePath.openWrite();

      await stream.pipe(fileStream);
      await fileStream.flush();
      await fileStream.close();

      debugPrint('Download complete: ${savePath.path}');
    } catch (e) {
      debugPrint('An error occurred: $e');
    }
  }
}
