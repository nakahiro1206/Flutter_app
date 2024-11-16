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
  void playAudio(AudioMetaData? audioToPlay, double bpm) async {
    if (audioToPlay != null) {
      try {
        final String filepath = audioToPlay.filepath;
        await audioPlayer.setFilePath(filepath);
        final double multiplier = bpm / audioToPlay.bpm;
        await audioPlayer.setSpeed(multiplier);
        await audioPlayer.play();
        debugPrint("Filepath: $filepath, BPM: $bpm");
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
    final bpmTemporary = useState<double>(120);
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
            playAudio(nextAudio, bpmTemporary.value);
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
            leading: isPlaying.value ? const Icon(
              Icons.audiotrack,
              color: Colors.pink,
              size: 30.0,
            ) : const Icon(
              Icons.stop_circle_rounded,
              color: Colors.pink,
              size: 30.0,
            ),
            title: Text(
                selectedAudio.value?.title ?? '',
                overflow: TextOverflow.ellipsis,
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
                onPressed: () {
                  resumeAudio(isPlaying.value, position.value, duration.value);
                  isPlaying.value = true;
                  },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow),
                    Text('Resume'),
                  ]// const Text(Icons.play_arrow, 'Resume'),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  pauseAudio();
                  isPlaying.value = false;
                  },
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
          value: bpmTemporary.value,
          min: 60,
          max: 200,
          divisions: 140,
          label: bpmTemporary.value.toStringAsFixed(1),
          onChanged: (double value) {
            bpmTemporary.value = value;
            debugPrint("tmp bpm: ${bpmTemporary.value}, "
                "tmp duration: ${duration.value}, "
                "tmp position: ${position.value}");
            if (audioPlayer.playing) {
              final AudioMetaData? selectedAudioMetaData = selectedAudio.value;
              if (selectedAudioMetaData != null) {
                final double baseBPM = selectedAudioMetaData.bpm;
                final double multiplier = value / baseBPM;
                audioPlayer.setSpeed(multiplier);
              }
            }
          },
        ),
        Text('temporary BPM: ${bpmTemporary.value}, base BPM: ${selectedAudio.value?.bpm.toString() ?? "null"}'),
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
              return GestureDetector(
                  onTap: () {
                  debugPrint("play");
                  selectedAudioIndex.value = index;
                  selectedAudio.value = data[index];
                  playAudio(data[index], bpmTemporary.value);
                },
                child: ListTile(
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
                          playAudio(data[index], bpmTemporary.value);
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
                )
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
