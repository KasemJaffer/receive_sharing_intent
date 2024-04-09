library receive_sharing_intent;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'src/receive_sharing_intent_mobile.dart';

part 'src/data/shared_media_file.dart';

abstract class ReceiveSharingIntent extends PlatformInterface {
  ReceiveSharingIntent() : super(token: _token);

  static final Object _token = Object();

  static ReceiveSharingIntent _instance = ReceiveSharingIntentMobile();

  /// The default instance of [ReceiveSharingIntent] to use.
  static ReceiveSharingIntent get instance => _instance;

  /// Platform-specific implementations should set this to their own
  /// platform-specific class that extends [SamplePluginPlatform] when they
  /// register themselves.
  static set instance(ReceiveSharingIntent instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Returns a [Future], which completes to one of the following:
  ///
  ///   * the initially stored media uri (possibly null), on successful invocation;
  ///   * a [PlatformException], if the invocation failed in the platform plugin.
  ///
  /// NOTE. The returned media on iOS (iOS ONLY) is already copied to a temp folder.
  /// So, you need to delete the file after you finish using it
  Future<List<SharedMediaFile>> getInitialMedia() {
    throw UnimplementedError('getInitialMedia() has not been implemented.');
  }

  /// Sets up a broadcast stream for receiving incoming media share change events.
  ///
  /// Returns a broadcast [Stream] which emits events to listeners as follows:
  ///
  ///   * a decoded data ([List]) event (possibly null) for each successful
  ///   event received from the platform plugin;
  ///   * an error event containing a [PlatformException] for each error event
  ///   received from the platform plugin.
  ///
  /// Errors occurring during stream activation or deactivation are reported
  /// through the `FlutterError` facility. Stream activation happens only when
  /// stream listener count changes from 0 to 1. Stream deactivation happens
  /// only when stream listener count changes from 1 to 0.
  ///
  /// If the app was started by a link intent or user activity the stream will
  /// not emit that initial one - query either the `getInitialMedia` instead.
  Stream<List<SharedMediaFile>> getMediaStream() {
    throw UnimplementedError('getMediaStream() has not been implemented.');
  }

  /// Call this method if you already consumed the callback
  /// and don't want the same callback again
  Future<dynamic> reset() {
    throw UnimplementedError('reset() has not been implemented.');
  }

  /// Initializes the plugin and sets the mock values for testing.
  @visibleForTesting
  static void setMockValues({
    required List<SharedMediaFile> initialMedia,
    required Stream<List<SharedMediaFile>> mediaStream,
  }) {
    ReceiveSharingIntent.instance = _ReceiveSharingIntentMock(
      initialMedia: List.from(initialMedia),
      mediaStream: mediaStream,
    );
  }
}

/// A mock implementation of [ReceiveSharingIntent] for testing.
class _ReceiveSharingIntentMock extends ReceiveSharingIntent {
  final List<SharedMediaFile> initialMedia;
  final Stream<List<SharedMediaFile>> mediaStream;

  _ReceiveSharingIntentMock({
    required this.initialMedia,
    required this.mediaStream,
  });

  @override
  Future<List<SharedMediaFile>> getInitialMedia() async {
    return initialMedia;
  }

  @override
  Stream<List<SharedMediaFile>> getMediaStream() {
    return mediaStream;
  }

  @override
  Future<dynamic> reset() async {
    return initialMedia.clear();
  }
}
