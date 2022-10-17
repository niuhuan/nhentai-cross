import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:nhentai/basic/channels/nhentai.dart';
import 'package:nhentai/basic/common/common.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late InAppWebViewController _webViewController;
  late CookieManager _cookieManager;

  @override
  void initState() {
    _cookieManager = CookieManager.instance();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Load web cookies"),
        actions: [
          IconButton(
            onPressed: () {
              _webViewController.loadUrl(
                  urlRequest:
                      URLRequest(url: Uri.parse('https://nhentai.net/')));
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () async {
              final body = await _webViewController.evaluateJavascript(
                  source: "navigator.userAgent");
              await nHentai.setUserAgent(body);

              // var cookies =
              // await _webViewController.evaluateJavascript(source: "document.cookie");
              //
              // if (cookies.startsWith("\"")) {
              //   cookies = cookies.replaceAll("\"", "");
              // }

              final cookies = await _cookieManager.getCookies(
                  url: Uri.parse('https://nhentai.net/'));
              print(cookies.map((e) => "${e.name}=${e.value}").join("; "));
              await nHentai.setCookie(
                  cookies.map((e) => "${e.name}=${e.value}").join("; "));
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: Uri.parse('https://nhentai.net/'),
        ),
        onLoadStart: (c, url) {
          print("onLoadStart");
          _webViewController = c;
        },
      ),
    );
  }
}
