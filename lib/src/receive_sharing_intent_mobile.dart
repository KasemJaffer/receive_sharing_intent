import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../receive_sharing_intent.dart';

class ReceiveSharingIntentMobile extends ReceiveSharingIntent {
  @visibleForTesting
  final mChannel = const MethodChannel('receive_sharing_intent/messages');

  @visibleForTesting
  final eChannelMedia =
      const EventChannel("receive_sharing_intent/events-media");

  static Stream<List<SharedMediaFile>>? _streamMedia;

  @override
  Future<List<SharedMediaFile>> getInitialMedia() async {
    final json = await mChannel.invokeMethod('getInitialMedia');
    if (json == null) return [];
    final encoded = jsonDecode(json);
    return encoded
        .map<SharedMediaFile>((file) => SharedMediaFile.fromMap(file))
        .toList();
  }

  @override
  Stream<List<SharedMediaFile>> getMediaStream() {
    if (_streamMedia == null) {
      final stream = eChannelMedia.receiveBroadcastStream().cast<String?>();
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

  @override
  Future<dynamic> reset() {
    return mChannel.invokeMethod('reset');
  }
}
