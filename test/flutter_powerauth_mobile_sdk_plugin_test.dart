import 'package:flutter_powerauth_mobile_sdk_plugin/src/powerauth/powerauth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/src/powerauth/powerauth_platform_interface.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/src/powerauth/powerauth_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterPowerauthMobileSdkPluginPlatform
    with MockPlatformInterfaceMixin
    implements PowerAuthPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final PowerAuthPlatform initialPlatform = PowerAuthPlatform.instance;

  test('$PowerAuthMethodChannel is the default instance', () {
    expect(initialPlatform, isInstanceOf<PowerAuthMethodChannel>());
  });

  test('getPlatformVersion', () async {
    PowerAuth flutterPowerauthMobileSdkPlugin = PowerAuth();
    MockFlutterPowerauthMobileSdkPluginPlatform fakePlatform = MockFlutterPowerauthMobileSdkPluginPlatform();
    PowerAuthPlatform.instance = fakePlatform;

    expect(await flutterPowerauthMobileSdkPlugin.getPlatformVersion(), '42');
  });
}
