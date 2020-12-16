import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void main() {
  const MethodChannel channel =
  const MethodChannel('receive_sharing_intent/messages');

  const _testUriString = "content://media/external/images/media/43993";

  WidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case "getInitialText":
          return _testUriString;
        case "getInitialLink":
          return _testUriString;
        case "getInitialLinkAsUri":
          return _testUriString;
        default:
          throw UnimplementedError();
      }
    });

  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getInitialText', () async {
    var actual = await ReceiveSharingIntent.getInitialText();
    expect(actual, _testUriString);
  });

  test('getInitialLink', () async {
    var actual = await ReceiveSharingIntent.getInitialLink();
    expect(actual, _testUriString);
  });

  test('getInitialLinkAsUri', () async {
    var actual = await ReceiveSharingIntent.getInitialLinkAsUri();
    expect(actual, Uri.parse(_testUriString));
  });
}
