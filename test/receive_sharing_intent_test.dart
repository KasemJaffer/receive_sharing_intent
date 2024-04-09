import 'package:flutter_test/flutter_test.dart';
import 'dart:async';

import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('setMockValues', () async {
    final expectedMediaFiles = [
      SharedMediaFile(path: 'path1', type: SharedMediaType.image),
      SharedMediaFile(path: 'path2', type: SharedMediaType.video),
    ];
    final streamController =
        StreamController<List<SharedMediaFile>>.broadcast();
    ReceiveSharingIntent.setMockValues(
      initialMedia: expectedMediaFiles,
      mediaStream: streamController.stream,
    );

    // Test getInitialMedia
    final mediaFiles = await ReceiveSharingIntent.instance.getInitialMedia();
    expect(mediaFiles.length, expectedMediaFiles.length);
    for (int i = 0; i < mediaFiles.length; i++) {
      expect(mediaFiles[i].path, expectedMediaFiles[i].path);
      expect(mediaFiles[i].type, expectedMediaFiles[i].type);
    }
    // END of getInitialMedia test

    // Test getMediaStream
    final emittedMediaFiles = <List<SharedMediaFile>>[];
    final subscription =
        ReceiveSharingIntent.instance.getMediaStream().listen((event) {
      emittedMediaFiles.add(event);
    });

    final expectedMediaFilesStream = [
      SharedMediaFile(path: 'path3', type: SharedMediaType.image),
      SharedMediaFile(path: 'path4', type: SharedMediaType.video),
    ];
    streamController.add(expectedMediaFilesStream);
    await Future.delayed(Duration.zero); // Allow stream to process

    expect(emittedMediaFiles.length, 1);
    expect(emittedMediaFiles[0].length, expectedMediaFiles.length);
    for (int i = 0; i < emittedMediaFiles[0].length; i++) {
      expect(emittedMediaFiles[0][i].path, expectedMediaFilesStream[i].path);
      expect(emittedMediaFiles[0][i].type, expectedMediaFilesStream[i].type);
    }

    subscription.cancel();
    streamController.close();
    // END of getMediaStream test

    // Test reset
    await ReceiveSharingIntent.instance.reset();
    final initialMedia = await ReceiveSharingIntent.instance.getInitialMedia();
    expect(initialMedia.isEmpty, true);
    // END of reset test
  });
}
