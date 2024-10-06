import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'audio_meta_data.dart';
import 'audio_meta_data_list_provider.dart';

enum Menu { remove, play }

class AudioMetaDataListDisplay extends StatefulHookConsumerWidget {
  const AudioMetaDataListDisplay({super.key});

  @override
  AudioMetaDataListDisplayState createState() => AudioMetaDataListDisplayState();
}

class AudioMetaDataListDisplayState extends ConsumerState<AudioMetaDataListDisplay> {
  @override
  void initState() {
    super.initState();
    // "ref" can be used in all life-cycles of a StatefulWidget.
    ref.read(audioMetaDataListProvider.notifier).load();
  }

  final AudioPlayer audioPlayer = AudioPlayer();

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  // play audio.
  void playAudio(AudioMetaData? audioToPlay, double bpmRatio) async {
    if (audioToPlay != null) {
      try {
        final String filepath = audioToPlay.filepath;
        await audioPlayer.setFilePath(filepath);
        await audioPlayer.setSpeed(bpmRatio);
        await audioPlayer.play();
        debugPrint("Filepath: $filepath, Speed: $bpmRatio");
      } catch (e) {
        debugPrint("playAudio failed: $e");
      }
    } else {
      debugPrint("No file selected");
    }
  }

  void pauseAudio() async {
    await audioPlayer.pause();
  }

  void resumeAudio(bool isPlaying, Duration? position, Duration? duration) async {
    if (isPlaying || position ==null || duration == null) { return; }
    if ( position >= duration ) {
      audioPlayer.seek(Duration.zero);
    }
    await audioPlayer.play();
  }

  Duration getMin(Duration position, Duration? duration) {
    if (duration == null) {
      return Duration.zero;
    }

    if (position.compareTo(duration) > 0) {
      // position > duration
      return duration;
    } else {
      return position;
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioMetaDataList = ref.watch(audioMetaDataListProvider);

    // general setting for audio playing.
    final selectedAudio = useState<AudioMetaData?>(null);
    final selectedAudioIndex = useState<int?>(null);
    final bpmMultiplier = useState<double>(1.0);
    final isPlaying = useState<bool>(false);
    // final isCompleted = useState<bool>(false);
    final duration = useState<Duration?>(const Duration(seconds: 0));
    final position = useState<Duration>(const Duration(seconds: 0));

    // useEffect
    useEffect(() {
      // Listen player states
      audioPlayer.playerStateStream.listen((event) async {
        isPlaying.value = event.playing;
        if (event.processingState == ProcessingState.completed) {
          // complete listening
          isPlaying.value = false;
          debugPrint("----------audio completed!");
          // audioMetaDataList might be consumed after render??
          final List<AudioMetaData>? val = ref.read(audioMetaDataListProvider.notifier).fetchData();
          final int? index = selectedAudioIndex.value;
          if (val != null && index != null) {
            debugPrint('Completed audio: ${val[index].title}, index: $index');
            final int nextIndex = (index + 1) % val.length;
            selectedAudioIndex.value = nextIndex;
            final AudioMetaData nextAudio = val[nextIndex];
            selectedAudio.value = nextAudio;
            playAudio(nextAudio, bpmMultiplier.value);
          }
        }
      });
      // Listen audio duration
      audioPlayer.durationStream.listen((newDuration) {
        duration.value = newDuration;
      });
      // Listen audio position
      audioPlayer.positionStream.listen((newPosition) {
        position.value = getMin(newPosition, duration.value);// newPosition;
      });
      return null;
    }, []);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListTile(
            leading: const Icon(
              Icons.audiotrack,
              color: Colors.pink,
              size: 30.0,
            ),
            title: Text(
                selectedAudio.value?.title ?? '',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                )
            ),
            // trailing: PopupMenuButton<Menu>(
          )
        ),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => resumeAudio(isPlaying.value, position.value, duration.value),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow),
                    Text('Resume'),
                  ]// const Text(Icons.play_arrow, 'Resume'),
                ),
              ),
              ElevatedButton(
                onPressed: () => pauseAudio(),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pause),
                    Text('Pause'),
                  ]// const Text(Icons.play_arrow, 'Resume'),
                ),
              ),
            ]
          )
        ),
        Slider(
          value: bpmMultiplier.value,
          min: 0.5,
          max: 2.0,
          divisions: 30,
          label: bpmMultiplier.value.toString(),
          onChanged: (double value) {
            bpmMultiplier.value = value;
            debugPrint("tmp bpm: ${bpmMultiplier.value}, "
                "tmp duration: ${duration.value}, "
                "tmp position: ${position.value}");
            if (audioPlayer.playing) {
              audioPlayer.setSpeed(bpmMultiplier.value);
            }
          },
        ),
        Text('BPM Multiplier: ${bpmMultiplier.value}x, '
          'base BPM: ${selectedAudio.value?.bpm.toString() ?? "null"}'),
        Slider(
          value: position.value.inMilliseconds.toDouble(),
          min: 0,
          max: duration.value?.inMilliseconds.toDouble() ?? 0,
          onChanged: (double val) {
            position.value = Duration(milliseconds: val.toInt());
            audioPlayer.seek(position.value);
          },
        ),
        Text('tmp: ${position.value.inMilliseconds.toDouble()}ms, '
            'max: ${duration.value?.inMilliseconds.toDouble() ?? 0}'),

        audioMetaDataList.when(
        data: (data) =>  SizedBox(
          height: 300,  // or any desired height
          child: ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Text('${index + 1}.'),
                title: Text(data[index].title),
                trailing: PopupMenuButton<Menu>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (Menu item) {
                    switch (item) {
                      case (Menu.play):
                        debugPrint("play");
                        selectedAudioIndex.value = index;
                        selectedAudio.value = data[index];
                        playAudio(data[index], bpmMultiplier.value);
                        break;

                      case (Menu.remove):
                        debugPrint("remove");
                        ref.read(audioMetaDataListProvider.notifier).remove(index);
                        if (index == selectedAudioIndex.value) {
                          selectedAudioIndex.value = null;
                          selectedAudio.value = null;
                        }
                        break;
                    }
                  },
                  offset: const Offset(-40, 0),
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<Menu>>[
                    const PopupMenuItem<Menu>(
                      value: Menu.play,
                      child: ListTile(
                        leading: Icon(Icons.play_arrow_outlined),
                        title: Text('Play'),
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<Menu>(
                      value: Menu.remove,
                      child: ListTile(
                        leading: Icon(Icons.delete_outline),
                        title: Text('Remove'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        error: (object, stackTrace) => const SizedBox(),
        loading: () => const SizedBox(),
      ),
      ],
    );
  }
}
