import 'package:flutter/material.dart';
import 'package:flutter_app/counter_view.dart';
import 'audio_downloader.dart';
import 'handle_audio_meta_data.dart';
import 'package:just_audio/just_audio.dart';

// https://pub.dev/packages/flutter_audio_waveforms/example

class AudioListScreen extends StatefulWidget {
  // const AudioListScreen({super.key});

  @override
  _AudioListScreenState createState() => _AudioListScreenState();
}

class _AudioListScreenState extends State<AudioListScreen> {
  // general setting for audio playing.
  List<AudioMetaData> _audioFiles = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  AudioMetaData? _selectedAudio;
  double _bpmMultiplier = 1.0;
  bool _isPlaying = false;
  bool _isCompleted = false;
  Duration? _duration = Duration.zero;
  Duration? _position = Duration.zero;

  @override
  void initState() {
    // Listen player states
    _audioPlayer.playerStateStream.listen((event) async {
      setState(() {
        _isPlaying = event.playing;
      });
      if (event.processingState == ProcessingState.completed) {
        setState(() {
          _isPlaying = false;
          _position = const Duration(seconds: 0);
          _isCompleted = true;
        });
      }
    });
    // Listen audio duration
    _audioPlayer.durationStream.listen((newDuration) {
      setState(() {
        _duration = newDuration;
      });
    });
    // Listen audio position
    _audioPlayer.positionStream.listen((newPosition) {
      setState(() {
        _position = newPosition;
      });
    });
    super.initState();
    _loadAudioFiles();
  }

  Future<void> _loadAudioFiles() async {
    debugPrint("load audio start");
    final audioMetaDataList = await loadAudioData();
    setState(() {
      _audioFiles = audioMetaDataList;
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playAudio() async {
    if (_selectedAudio != null) {
      try {
        String fp = _selectedAudio!.filepath;
        debugPrint("_audioPlayer.setFilePath: ${_selectedAudio!.filepath}");
        await _audioPlayer.setFilePath(fp);
        debugPrint("_audioPlayer.setSpeed: $_bpmMultiplier");
        await _audioPlayer.setSpeed(_bpmMultiplier);
        debugPrint("speed is set");

        await _audioPlayer.play();
        debugPrint("audio is playing");
      } catch (e) {
        debugPrint("_playAudio failed: $e");
      }
    } else {
      debugPrint("No file selected");
    }
  }

  String getDuration(double value) {
    Duration duration = Duration(milliseconds: value.round());
    return [duration.inHours, duration.inMinutes, duration.inSeconds]
        .map((e) => e.remainder(60).toString().padLeft(2, "0"))
        .join(":");
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButton<AudioMetaData>(
          hint: const Text('Select an audio file'),
          value: _selectedAudio,
          isExpanded: true,
          items: _audioFiles.map((AudioMetaData audioMetaData) {
            return DropdownMenuItem<AudioMetaData>(
              value: audioMetaData,
              child: Text(
                  audioMetaData.title,
                  overflow: TextOverflow.ellipsis
              ),
            );
          }).toList(),
          onChanged: (AudioMetaData? newValue) {
            setState(() {
              if (newValue != null) {
                _selectedAudio = newValue;
              }
              else {
                debugPrint("selected file is null. Can't change _selectedAudio");
              }
            });
          },
        ),
        ElevatedButton(
          onPressed: _playAudio,
          child: const Text('Play'),
        ),
        Slider(
          value: _bpmMultiplier,
          min: 0.5,
          max: 2.0,
          divisions: 30,
          label: _bpmMultiplier.toString(),
          onChanged: (double value) {
            setState(() {
              _bpmMultiplier = value;
              if (_audioPlayer.playing) {
                _audioPlayer.setSpeed(_bpmMultiplier);
              }
            });
          },
        ),
        Text('BPM Multiplier: ${_bpmMultiplier}x, base BPM: ${(_selectedAudio == null)?"null": _selectedAudio!.bpm.toString()}'),
        Slider(
          value: _position!.inMilliseconds.toDouble(),
          min: 0,
          max: _duration!.inMilliseconds.toDouble(),
          onChanged: (double val) {
            setState((){
              _position = Duration(milliseconds: val.toInt());
              _audioPlayer.seek(_position);
            });
          },
        ),

        // button to move to download page.
        AudioDownloader(),
        CounterWidget()
      ],
    );
  }
}
