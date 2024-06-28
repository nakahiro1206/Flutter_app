import 'package:flutter/material.dart';
import 'audio_list_screen.dart';
import 'audio_downloader.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DJ App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final AudioDownloader _audioDownloader = AudioDownloader();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DJ App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
                  await _audioDownloader.downloadAudio(url);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Download complete!'),
                    )
                  );
                }
              },
              child: const Text('Download Audio'),
            ),

            // This component is Audio list. Next page.
            //
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AudioListScreen()),
                );
              },
              child: const Text('Go to Audio List'),
            ),
          ],
        ),
      ),
    );
  }
}
