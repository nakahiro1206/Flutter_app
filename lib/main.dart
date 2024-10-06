import 'package:flutter/material.dart';
import 'package:flutter_app/home_view.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'audio_downloader.dart';
// import 'audio_play_screen.dart';
import 'package:flutter_app/step_bpm.dart' show PedometerDisplay;
import 'equalizer.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
        title: 'DJ App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const HomeScreen(),
      );
    // );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  // final TextEditingController _controller = TextEditingController();
  // final AudioDownloader _audioDownloader = AudioDownloader();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Streaming App'),
      ),
      body: SingleChildScrollView(
        child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // AudioListScreen(),
            const AudioMetaDataListDisplay(),
            // button to move to download page.
            const AudioDownloader(),
            const EqualizerPage(),
            PedometerDisplay()
          ],
        ),
        ),
      )
    );
  }
}
