import 'package:flutter/material.dart';
import 'dart:async';

import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription _intentDataStreamSubscription;
  List<Uri> _sharedFiles;

  @override
  void initState() {
    super.initState();

    // For sharing images coming from outside the app while the app is in the memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getIntentDataStreamAsUri().listen(
            (List<Uri> uris) {
      setState(() {
        _sharedFiles = uris;
      });
    }, onError: (err) {
      print("Latest Intent Data error: $err");
    });

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialIntentDataAsUri().then((List<Uri> uris) {
      setState(() {
        _sharedFiles = uris;
      });
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Number of shared files: ${_sharedFiles?.length ?? 0}'),
        ),
      ),
    );
  }
}
