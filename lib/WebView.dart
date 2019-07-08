import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'Data.dart';

DateTime currentDateTime = DateTime.now();

/// The main widget shows the events of the selected subjects and directs the
/// user to other widgets.
class WebViewPage extends StatefulWidget {
  final Data data;
  final String title = "AgendaApp";

  WebViewPage({Key key, title, this.data}) : super(key: key);

  @override
  WebViewState createState() => WebViewState(data);
}

class WebViewState extends State<WebViewPage> with TickerProviderStateMixin {
  AnimationController _controller;
  WebViewController webViewController;
  Data data = new Data();

  WebViewState(Data data) {
    this.data = data;
  }

  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AgendaApp'),
      ),
      body: WebView(
        initialUrl: data.url,
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}
