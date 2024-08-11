import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'audio_play_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
  // final TextEditingController _controller = TextEditingController();
  // final AudioDownloader _audioDownloader = AudioDownloader();

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
            AudioListScreen(),
          ],
        ),
      ),
    );
  }
}

class ResultNotifier extends StateNotifier<String> {
  ResultNotifier() : super(defaultResultValue);

  static const defaultResultValue = '遷移先に移動';

  void initValue() {
    // state更新時にProviderを介してConsumer配下のWidgetがリビルドされる
    state = defaultResultValue;
  }

  void updateText(String str) {
    // state更新時にProviderを介してConsumer配下のWidgetがリビルドされる
    state = str;
  }

  void refresh() {
    initValue();
  }
}

/// 状態の保持と操作を行うProvider
/// StateNotifierを継承した操作用のクラス(ResultNotifier)と、状態の型を定義します。
final resultProvider = StateNotifierProvider.autoDispose<ResultNotifier, String>((ref) {
  return ResultNotifier();
});
