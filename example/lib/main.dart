import 'package:flutter/material.dart';
import 'dart:async';

import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final List<StreamSubscription> streamSubscriptions = [];

  final List<SharedMediaFile> sharedFiles = [];

  SharedTextInfo? sharedText;

  @override
  void initState() {
    super.initState();

    // For sharing images coming from outside the app while the app is in the memory
    final sub1 = ReceiveSharingIntent.getMediaStream().listen((final List<SharedMediaFile> value) {
      print("Shared Media Stream: ${value.map((e) => e.toString()).join("\n\n")}");

      setState(() {
        sharedFiles
          ..clear()
          ..addAll(value);
      });
    }, onError: (err) {
      print("getIntentDataStream error: $err");
    });
    streamSubscriptions.add(sub1);

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> value) {
      print("Shared Media Init: ${value.map((e) => e.toString()).join("\n\n")}");

      setState(() {
        sharedFiles
          ..clear()
          ..addAll(value);
      });
    });

    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    final sub2 = ReceiveSharingIntent.getTextStream().listen((value) {
      print("Shared Text Stream: $value");

      setState(() {
        sharedText = value;
      });
    }, onError: (err) {
      print("getLinkStream error: $err");
    });
    streamSubscriptions.add(sub2);

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialText().then((  value) {
      print("Shared Text Stream: $value");
      if (value == null) {
        return;
      }

      setState(() {
        sharedText = value;
      });
    });
  }

  @override
  void setState(fn) {
    if (!mounted) return;
    super.setState(fn);
  }

  @override
  void dispose() {
    streamSubscriptions.forEach((element) {
      element.cancel();
    });

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const textStyleBold = const TextStyle(fontWeight: FontWeight.bold);

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              children: <Widget>[
                Text("Shared files:", style: textStyleBold),
                Text("${sharedFiles.map((e) => e.toString()).join("\n    -------------------    \n")}"),
                SizedBox(height: 100),
                Text("Shared urls/text:", style: textStyleBold),
                Text(sharedText?.toString() ?? ""),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
