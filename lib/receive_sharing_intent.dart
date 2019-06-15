import 'dart:async';

import 'package:flutter/services.dart';

class ReceiveSharingIntent {
  static const MethodChannel _mChannel =
  const MethodChannel('receive_sharing_intent/messages');

  static const EventChannel _eChannelImage = const EventChannel(
      "receive_sharing_intent/events-image");
  static const EventChannel _eChannelLink = const EventChannel(
      "receive_sharing_intent/events-link");

  static Stream<List<String>> _streamImage;
  static Stream<String> _streamLink;

  /// Returns a [Future], which completes to one of the following:
  ///
  ///   * the initially stored image uri (possibly null), on successful invocation;
  ///   * a [PlatformException], if the invocation failed in the platform plugin.
  static Future<List<String>> getInitialIntentData() async {
    final List<dynamic> initialIntentData =
    await _mChannel.invokeMethod('getInitialIntentData');
    return initialIntentData?.map((data) => data.toString())?.toList();
  }

  /// Returns a [Future], which completes to one of the following:
  ///
  ///   * the initially stored link (possibly null), on successful invocation;
  ///   * a [PlatformException], if the invocation failed in the platform plugin.
  static Future<String> getInitialLink() async {
    return await _mChannel.invokeMethod('getInitialLink');
  }

  /// A convenience method that returns the initially stored image uri
  /// as a new [Uri] object.
  ///
  /// If the link is not valid as a URI or URI reference,
  /// a [FormatException] is thrown.
  static Future<List<Uri>> getInitialIntentDataAsUri() async {
    final List<String> data = await getInitialIntentData();
    if (data == null) return null;
    return data.map((value) => Uri.parse(value)).toList();
  }

  /// A convenience method that returns the initially stored link
  /// as a new [Uri] object.
  ///
  /// If the link is not valid as a URI or URI reference,
  /// a [FormatException] is thrown.
  static Future<Uri> getInitialLinkAsUri() async {
    final String data = await getInitialLink();
    if (data == null) return null;
    return Uri.parse(data);
  }

  /// Sets up a broadcast stream for receiving incoming image share change events.
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
  /// If the app was stared by a link intent or user activity the stream will
  /// not emit that initial one - query either the `getInitialIntentData` instead.
  static Stream<List<String>> getIntentDataStream() {
    if (_streamImage == null) {
      final stream = _eChannelImage
          .receiveBroadcastStream("image")
          .cast<List<dynamic>>();
      _streamImage = stream.transform<List<String>>(
        new StreamTransformer<List<dynamic>, List<String>>.fromHandlers(
          handleData: (List<dynamic> data, EventSink<List<String>> sink) {
            if (data == null) {
              sink.add(null);
            } else {
              sink.add(data.map((value) => value as String).toList());
            }
          },
        ),
      );
    }
    return _streamImage;
  }

  /// Sets up a broadcast stream for receiving incoming link change events.
  ///
  /// Returns a broadcast [Stream] which emits events to listeners as follows:
  ///
  ///   * a decoded data ([String]) event (possibly null) for each successful
  ///   event received from the platform plugin;
  ///   * an error event containing a [PlatformException] for each error event
  ///   received from the platform plugin.
  ///
  /// Errors occurring during stream activation or deactivation are reported
  /// through the `FlutterError` facility. Stream activation happens only when
  /// stream listener count changes from 0 to 1. Stream deactivation happens
  /// only when stream listener count changes from 1 to 0.
  ///
  /// If the app was stared by a link intent or user activity the stream will
  /// not emit that initial one - query either the `getInitialLink` instead.
  static Stream<String> getLinkStream() {
    if (_streamLink == null) {
      _streamLink = _eChannelLink
          .receiveBroadcastStream("link")
          .cast<String>();
    }
    return _streamLink;
  }

  /// A convenience transformation of the stream to a `Stream<List<Uri>>`.
  ///
  /// If the value is not valid as a URI or URI reference,
  /// a [FormatException] is thrown.
  ///
  /// Refer to `getIntentDataStream` about error/exception details.
  ///
  /// If the app was started by a share intent or user activity the stream will
  /// not emit that initial uri - query either the `getInitialIntentDataAsUri` instead.
  static Stream<List<Uri>> getIntentDataStreamAsUri() {
    return getIntentDataStream().transform<List<Uri>>(
      new StreamTransformer<List<String>, List<Uri>>.fromHandlers(
        handleData: (List<String> data, EventSink<List<Uri>> sink) {
          if (data == null) {
            sink.add(null);
          } else {
            sink.add(data.map((value) => Uri.parse(value)).toList());
          }
        },
      ),
    );
  }

  /// A convenience transformation of the stream to a `Stream<Uri>`.
  ///
  /// If the value is not valid as a URI or URI reference,
  /// a [FormatException] is thrown.
  ///
  /// Refer to `getLinkStream` about error/exception details.
  ///
  /// If the app was started by a share intent or user activity the stream will
  /// not emit that initial uri - query either the `getInitialLinkAsUri` instead.
  static Stream<Uri> getLinkStreamAsUri() {
    return getLinkStream().transform<Uri>(
      new StreamTransformer<String, Uri>.fromHandlers(
        handleData: (String data, EventSink<Uri> sink) {
          if (data == null) {
            sink.add(null);
          } else {
            sink.add(Uri.parse(data));
          }
        },
      ),
    );
  }
}
