import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void main() {
  const MethodChannel channel =
      const MethodChannel('receive_sharing_intent/messages');

  const _testUriString = "content://media/external/images/media/43993";

  var handler = (methodCall) async {
    switch (methodCall.method) {
      case "getInitialText":
        return _testUriString;
      case "getInitialTextAsUri":
        return Uri.parse(_testUriString);
      default:
        throw UnimplementedError();
    }
  };

  testWidgets("getInitialText", (widgetTester) async {
    widgetTester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);

    var actual = await ReceiveSharingIntent.getInitialText();
    expect(actual, _testUriString);
  });

  testWidgets('getInitialTextAsUri', (tester) async {
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);

    var actual = await ReceiveSharingIntent.getInitialTextAsUri();
    expect(actual, Uri.parse(_testUriString));
  });
}
