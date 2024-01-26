import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

class ReceiveSharingIntent {
  static const _mChannel =
      const MethodChannel('receive_sharing_intent/messages');
  static const _eChannelMedia =
      const EventChannel("receive_sharing_intent/events-media");

  static Stream<List<SharedMediaFile>>? _streamMedia;

  /// Returns a [Future], which completes to one of the following:
  ///
  ///   * the initially stored media uri (possibly null), on successful invocation;
  ///   * a [PlatformException], if the invocation failed in the platform plugin.
  ///
  /// NOTE. The returned media on iOS (iOS ONLY) is already copied to a temp folder.
  /// So, you need to delete the file after you finish using it
  static Future<List<SharedMediaFile>> getInitialMedia() async {
    final json = await _mChannel.invokeMethod('getInitialMedia');
    if (json == null) return [];
    final encoded = jsonDecode(json);
    return encoded
        .map<SharedMediaFile>((file) => SharedMediaFile.fromMap(file))
        .toList();
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
  static Stream<List<SharedMediaFile>> getMediaStream() {
    if (_streamMedia == null) {
      final stream = _eChannelMedia.receiveBroadcastStream().cast<String?>();
      _streamMedia = stream.transform<List<SharedMediaFile>>(
        StreamTransformer<String?, List<SharedMediaFile>>.fromHandlers(
          handleData: (data, sink) {
            if (data == null) {
              sink.add(<SharedMediaFile>[]);
            } else {
              final encoded = jsonDecode(data);
              sink.add(encoded
                  .map<SharedMediaFile>((file) => SharedMediaFile.fromMap(file))
                  .toList());
            }
          },
        ),
      );
    }
    return _streamMedia!;
  }

  /// Call this method if you already consumed the callback
  /// and don't want the same callback again
  static Future<dynamic> reset() {
    return _mChannel.invokeMethod('reset');
  }
}

class SharedMediaFile {
  /// Shared file path, url or the text
  /// NOTE. for iOS only, all files are copied to a temp folder
  final String path;

  /// Video thumbnail
  final String? thumbnail;

  /// Video duration in milliseconds
  final int? duration;

  /// Shared media type
  final SharedMediaType type;

  /// Mime type of the file.
  /// i.e. image/jpeg, video/mp4, text/plain
  final String? mimeType;

  /// Post message iOS ONLY
  final String? message;

  SharedMediaFile({
    required this.path,
    required this.type,
    this.thumbnail,
    this.duration,
    this.mimeType,
    this.message,
  });

  SharedMediaFile.fromMap(Map<String, dynamic> json)
      : path = json['path'],
        thumbnail = json['thumbnail'],
        duration = json['duration'],
        type = SharedMediaType.fromValue(json['type']),
        mimeType = json['mimeType'],
        message = json['message'];

  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'thumbnail': thumbnail,
      'duration': duration,
      'type': type.value,
      'mimeType': mimeType,
      'message': message,
    };
  }
}

enum SharedMediaType {
  image('image'),
  video('video'),
  text('text'),
  file('file'),
  url('url');

  final String value;

  const SharedMediaType(this.value);

  static SharedMediaType fromValue(String value) {
    return SharedMediaType.values.firstWhere((e) => e.value == value);
  }
}
