import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: MusicPlayerScreen(),
//     );
//   }
// }

class MusicPlayerScreen extends StatefulWidget {
  @override
  _MusicPlayerScreenState createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  AudioPlayer _player = AudioPlayer();
  List<File> _audioFiles = [];
  File? _selectedFile;
  double _bpmMultiplier = 1.0;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _loadAudioFiles();
  }

  Future<void> _loadAudioFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    setState(() {
      _audioFiles = directory
          .listSync()
          .where((item) => item.path.endsWith(".mp3"))
          .map((item) => File(item.path))
          .toList();
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _playAudio() async {
    if (_selectedFile != null) {
      await _player.setFilePath(_selectedFile!.path);
      _player.setSpeed(_bpmMultiplier);
      _player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Player'),
      ),
      body: Column(
        children: [
          DropdownButton<File>(
            hint: const Text('Select an audio file'),
            value: _selectedFile,
            items: _audioFiles.map((File file) {
              return DropdownMenuItem<File>(
                value: file,
                child: Text(file.path.split('/').last),
              );
            }).toList(),
            onChanged: (File? newValue) {
              setState(() {
                if (newValue != null) {
                  _selectedFile = newValue;
                }
                else {
                  debugPrint("selected file is null. Can't change _selectedFile");
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
            divisions: 15,
            label: _bpmMultiplier.toString(),
            onChanged: (double value) {
              setState(() {
                _bpmMultiplier = value;
                if (_player.playing) {
                  _player.setSpeed(_bpmMultiplier);
                }
              });
            },
          ),
          Text('BPM Multiplier: ${_bpmMultiplier.toStringAsFixed(2)}x'),
        ],
      ),
    );
  }
}
