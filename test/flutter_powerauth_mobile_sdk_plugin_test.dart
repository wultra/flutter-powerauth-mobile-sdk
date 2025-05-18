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

  @override
  Future<bool> canStartActivation(String instanceId) {
    // TODO: implement canStartActivation
    throw UnimplementedError();
  }

  @override
  Future<void> changePassword(String instanceId, PowerAuthPassword oldPassword, PowerAuthPassword newPassword) {
    // TODO: implement changePassword
    throw UnimplementedError();
  }

  @override
  Future<void> configure({
    required String instanceId,
    required PowerAuthConfiguration configuration,
    PowerAuthClientConfiguration? clientConfiguration,
    PowerAuthBiometryConfiguration? biometryConfiguration,
    PowerAuthKeychainConfiguration? keychainConfiguration,
    PowerAuthSharingConfiguration? sharingConfiguration,
  }) {
    // TODO: implement configure
    throw UnimplementedError();
  }

  @override
  Future<PowerAuthCreateActivationResult> createActivation(String instanceId, PowerAuthActivation activation) {
    // TODO: implement createActivation
    throw UnimplementedError();
  }

  @override
  Future<void> deconfigure(String instanceId) {
    // TODO: implement deconfigure
    throw UnimplementedError();
  }

  @override
  Future<PowerAuthActivationStatus> fetchActivationStatus(String instanceId) {
    // TODO: implement fetchActivationStatus
    throw UnimplementedError();
  }

  @override
  Future<String?> getActivationFingerprint(String instanceId) {
    // TODO: implement getActivationFingerprint
    throw UnimplementedError();
  }

  @override
  Future<String?> getActivationIdentifier(String instanceId) {
    // TODO: implement getActivationIdentifier
    throw UnimplementedError();
  }

  @override
  Future<bool> hasPendingActivation(String instanceId) {
    // TODO: implement hasPendingActivation
    throw UnimplementedError();
  }

  @override
  Future<bool> hasValidActivation(String instanceId) {
    // TODO: implement hasValidActivation
    throw UnimplementedError();
  }

  @override
  Future<bool> isConfigured(String instanceId) {
    // TODO: implement isConfigured
    throw UnimplementedError();
  }

  @override
  Future<String> offlineSignature(String instanceId, PowerAuthAuthentication authentication, String uriId, String nonce, [String? body]) {
    // TODO: implement offlineSignature
    throw UnimplementedError();
  }

  @override
  Future<void> persistActivation(String instanceId, PowerAuthAuthentication authentication) {
    // TODO: implement persistActivation
    throw UnimplementedError();
  }

  @override
  Future<void> removeActivationLocal(String instanceId) {
    // TODO: implement removeActivationLocal
    throw UnimplementedError();
  }

  @override
  Future<void> removeActivationWithAuthentication(String instanceId, PowerAuthAuthentication authentication) {
    // TODO: implement removeActivationWithAuthentication
    throw UnimplementedError();
  }

  @override
  Future<PowerAuthAuthorizationHttpHeader> requestGetSignature(String instanceId, PowerAuthAuthentication authentication, String uriId, [Map<String, String>? queryParams]) {
    // TODO: implement requestGetSignature
    throw UnimplementedError();
  }

  @override
  Future<PowerAuthAuthorizationHttpHeader> requestSignature(String instanceId, PowerAuthAuthentication authentication, String method, String uriId, [String? body]) {
    // TODO: implement requestSignature
    throw UnimplementedError();
  }

  @override
  Future<void> validatePassword(String instanceId, PowerAuthPassword password) {
    // TODO: implement validatePassword
    throw UnimplementedError();
  }

  @override
  Future<bool> verifyServerSignedData(String instanceId, String data, String signature, bool useMasterKey) {
    // TODO: implement verifyServerSignedData
    throw UnimplementedError();
  }
  
  @override
  Future<void> addBiometryFactor(String instanceId, PowerAuthPassword password, [PowerAuthBiometricPrompt? prompt]) {
    // TODO: implement addBiometryFactor
    throw UnimplementedError();
  }
  
  @override
  Future<PowerAuthBiometryInfo> getBiometryInfo(String instanceId) {
    // TODO: implement getBiometryInfo
    throw UnimplementedError();
  }
  
  @override
  Future<bool> hasBiometryFactor(String instanceId) {
    // TODO: implement hasBiometryFactor
    throw UnimplementedError();
  }
  
  @override
  Future<void> removeBiometryFactor(String instanceId) {
    // TODO: implement removeBiometryFactor
    throw UnimplementedError();
  }
}

void main() {
  final PowerAuthPlatform initialPlatform = PowerAuthPlatform.instance;

  test('$PowerAuthMethodChannel is the default instance', () {
    expect(initialPlatform, isInstanceOf<PowerAuthMethodChannel>());
  });

  test('getPlatformVersion', () async {
    PowerAuth flutterPowerauthMobileSdkPlugin = PowerAuth("testID");
    MockFlutterPowerauthMobileSdkPluginPlatform fakePlatform = MockFlutterPowerauthMobileSdkPluginPlatform();
    PowerAuthPlatform.instance = fakePlatform;

    expect(await flutterPowerauthMobileSdkPlugin.getPlatformVersion(), '42');
  });
}
