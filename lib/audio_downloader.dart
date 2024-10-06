import 'package:flutter/material.dart';
import 'package:flutter_app/audio_meta_data.dart';
import 'package:flutter_app/audio_meta_data_list_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'create_random_string.dart';

class AudioDownloader extends HookConsumerWidget {
  const AudioDownloader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextEditingController controller = TextEditingController();
    final YoutubeExplode yt = YoutubeExplode();
    final audioMetaDataList = ref.watch(audioMetaDataListProvider);
    final randomStringGenerator = RandomStringGenerator();

    Future<(String?, String?)> downloadAudio(String url, List<AudioMetaData> syncAudioMetaDataList) async {
      try {
        // Get video metadata
        final video = await yt.videos.get(url);
        final manifest = await yt.videos.streamsClient.getManifest(video.id);
        final audioStreamInfo = manifest.audioOnly.withHighestBitrate();
        final String title = video.title;

        // Get the directory to save the file
        final Directory directory = await getApplicationDocumentsDirectory();

        // // remove inappropriate symbols
        // final RegExp disallowedChars = RegExp(r'[<>:"/\\|?*\x00-\x1F\x7F]');
        // title = title.replaceAll(disallowedChars, '');
        // title = title.trim();

        final String filepath = randomStringGenerator.createCryptoRandomFilepath(syncAudioMetaDataList, directory.path);
        debugPrint(filepath);

        // Download the audio stream
        final stream = yt.videos.streamsClient.get(audioStreamInfo);
        final fileStream = File(filepath).openWrite();

        await stream.pipe(fileStream);
        await fileStream.flush();
        await fileStream.close();

        debugPrint('Download complete: $filepath');
        return (filepath, title);
      } catch (e) {
        debugPrint('An error occurred during downloading: $e');
        return (null, null);
      }
    }

    Future<void> handlePress(String url, List<AudioMetaData> data) async {
      final (filepath, title) = await downloadAudio(url, data);
      if (filepath != null && title != null) {
        final AudioMetaData? newAudioMetaData = await createAudioMetaDataFromFilepathString(filepath, title);
        if (newAudioMetaData != null) {
          ref.read(audioMetaDataListProvider.notifier).add(newAudioMetaData);
        }
      }
    }

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
                          controller: controller,
                          decoration: const InputDecoration(
                            labelText: 'Enter YouTube Music URL',
                          ),
                        ),
                        const SizedBox(height: 20),

                        // YouTube Downloader
                        audioMetaDataList.when(
                          data: (data) => ElevatedButton(
                            onPressed: () async {
                              final url = controller.text;
                              if (url.isNotEmpty) {
                                await handlePress(url, data);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                    const SnackBar(
                                      content: Text('Download complete!'),
                                    )
                                  );
                                }
                              }
                            },
                            child: const Text('Download Audio'),
                          ),
                          error: (object, stackTrace) {
                            return const Text("Error occurred");
                          },
                          loading: () => const CircularProgressIndicator(
                            strokeWidth: 3.0,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
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