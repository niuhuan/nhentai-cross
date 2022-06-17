import 'package:flutter/material.dart';
import 'package:nhentai/basic/channels/nhentai.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController _webViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Load web cookies"),
        actions: [
          IconButton(onPressed: () {
            _webViewController.loadUrl('https://nhentai.net/');
          }, icon: const Icon(Icons.refresh),),
          IconButton(onPressed: () async {
            final cookies = await _webViewController.runJavascriptReturningResult(
              'document.cookie',
            );
            await nHentai.setCookie(cookies);
            await nHentai.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36');
            Navigator.of(context).pop();
          }, icon: const Icon(Icons.check),),
        ],
      ),
      body: WebView(
        initialUrl: 'https://nhentai.net/',
        onWebViewCreated: (WebViewController webViewController) {
          _webViewController = webViewController;
        },
        javascriptMode: JavascriptMode.unrestricted,
        userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36',
      ),
    );
  }
}
