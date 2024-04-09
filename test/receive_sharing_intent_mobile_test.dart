import 'package:flutter_test/flutter_test.dart';
import 'dart:async';
import 'dart:convert';

import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:receive_sharing_intent/src/receive_sharing_intent_mobile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late final instance = ReceiveSharingIntentMobile();
  late final methodChannel = instance.mChannel;
  late final eventChannel = instance.eChannelMedia;

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, null);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(eventChannel, null);
  });

  test('getInitialMedia', () async {
    final expectedMediaFiles = [
      SharedMediaFile(path: 'path1', type: SharedMediaType.image),
      SharedMediaFile(path: 'path2', type: SharedMediaType.video),
    ];
    final json =
        jsonEncode(expectedMediaFiles.map((file) => file.toMap()).toList());

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (methodCall) async {
      if (methodCall.method == 'getInitialMedia') {
        return json;
      }
      return null;
    });

    final mediaFiles = await instance.getInitialMedia();
    expect(mediaFiles.length, expectedMediaFiles.length);
    for (int i = 0; i < mediaFiles.length; i++) {
      expect(mediaFiles[i].path, expectedMediaFiles[i].path);
      expect(mediaFiles[i].type, expectedMediaFiles[i].type);
    }
  });

  test('getMediaStream', () async {
    final expectedMediaFiles = [
      SharedMediaFile(path: 'path1', type: SharedMediaType.image),
      SharedMediaFile(path: 'path2', type: SharedMediaType.video),
    ];
    final json =
        jsonEncode(expectedMediaFiles.map((file) => file.toMap()).toList());

    final streamController = StreamController<String?>.broadcast();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
      eventChannel,
      MockStreamHandler.inline(
        onListen: (args, events) {
          streamController.stream.listen(events.success);
        },
      ),
    );

    final emittedMediaFiles = <List<SharedMediaFile>>[];
    final subscription = instance.getMediaStream().listen((event) {
      emittedMediaFiles.add(event);
    });

    streamController.add(json);

    await Future.delayed(Duration.zero); // Allow stream to process

    expect(emittedMediaFiles.length, 1);
    expect(emittedMediaFiles[0].length, expectedMediaFiles.length);
    for (int i = 0; i < emittedMediaFiles[0].length; i++) {
      expect(emittedMediaFiles[0][i].path, expectedMediaFiles[i].path);
      expect(emittedMediaFiles[0][i].type, expectedMediaFiles[i].type);
    }

    subscription.cancel();
    streamController.close();
  });

  test('reset', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (methodCall) async {
      if (methodCall.method == 'reset') {
        return null;
      }
      return null;
    });

    await instance.reset();

    // No exception means success
    expect(true, true);
  });
}
