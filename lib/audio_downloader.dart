import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AudioDownloader extends StatefulWidget {

  @override
  _AudioDownloaderState createState() => _AudioDownloaderState();
}

class _AudioDownloaderState extends State<AudioDownloader> {
  final TextEditingController _controller = TextEditingController();
  final YoutubeExplode yt = YoutubeExplode();

  Future<void> downloadAudio(String url) async {
    try {
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
      // AddAudioMetaData
    } catch (e) {
      debugPrint('An error occurred: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ElevatedButton(
            child: const Text('Click to download audio'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return Scaffold(
                    appBar: AppBar(
                      title: const Text('Download audio from YouTube'),
                    ),
                    body: Column(
                      children: [
                        TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            labelText: 'Enter YouTube Music URL',
                          ),
                        ),
                        const SizedBox(height: 20),

                        // YouTube Downloader
                        ElevatedButton(
                          onPressed: () async {
                            final url = _controller.text;
                            if (url.isNotEmpty) {
                              await downloadAudio(url);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Download complete!'),
                                  )
                              );
                            }
                          },
                          child: const Text('Download Audio'),
                        ),
                      ],
                    ),
                  );
                })
              );
            }

          )
        ]
      )
    );
  }
}