import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/src/powerauth/powerauth_method_channel.dart';

// TODO(pre-release): this is only a sanity test!
// Remove or provide concrete impl before beta.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  PowerAuthMethodChannel platform = PowerAuthMethodChannel();
  const MethodChannel channel = MethodChannel('flutter_powerauth_mobile_sdk_plugin');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
