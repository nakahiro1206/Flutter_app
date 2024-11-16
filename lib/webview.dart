import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewApp extends StatefulWidget {
  const WebViewApp({super.key});

  @override
  State<WebViewApp> createState() => _WebViewAppState();
}

class _WebViewAppState extends State<WebViewApp> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('Print',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint(message. message);
        },)
      ..loadRequest(
        Uri.parse('https://flutter.dev/'),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return Scaffold(
                      appBar: AppBar(
                        // title: const Text('Flutter WebView'),
                        title: ElevatedButton(onPressed: () async {
                          final String contents = await controller.runJavaScript('document.documentElement.innerHTML') as String;
                          final String str = contents;
                          debugPrint(str);
                          }, child: const Text("Scrape")
                        ),
                      ),
                      body: WebViewWidget(controller: controller),
                      // SingleChildScrollView(
                      // child: Column(
                      //   children: [
                      //     WebViewWidget(controller: controller),
                      //     ElevatedButton(onPressed: () async {
                      //       final Object contents = await controller.runJavaScriptReturningResult('document.documentElement.innerHTML');
                      //       final String str = contents.toString();
                      //       debugPrint(str);
                      //       }, child: const Text("Scrape")
                      //     ),
                      //   ]
                      // ),
                      // )
                    );
                  }));
                },
                child: const Text('Move to browser page'))
          ],
        )
    );
  }
}
