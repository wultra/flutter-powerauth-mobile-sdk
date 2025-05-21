import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/suites/test_suite.dart';

class PowerAuthPasswordTests extends TestSuiteWithActivation {

  @override
  List<Future<void> Function()> getTests() => [
    testValidatePassword,
    testChangePassword,
    testReuseUsedPasswordObject,
    testReusePasswordObjectInAuth,
    testReuseUsedPasswordObjectInAuth,
    testWrongPassword
  ];

  @override
  Future<void> beforeEach() async {
    await super.beforeEach();
    await helper.prepareActiveActivation(await credentials.validPasswordObject());
  }

  // --- ACTUAL TESTS STARTS HERE ---

  Future<void> testValidatePassword() async {
      // Valid password
    await expect(sdk.validatePassword(await credentials.validPasswordObject())).toSucceed();
    // Wrong password
    await expect(sdk.validatePassword(await credentials.invalidPasswordObject())).toThrow(PowerAuthErrorCode.authenticationError);
  }

  Future<void> testChangePassword() async {
    await expect(sdk.changePassword(await credentials.validPasswordObject(), await credentials.invalidPasswordObject())).toSucceed();
    await expect(sdk.validatePassword(await credentials.invalidPasswordObject())).toSucceed();
    await expect(sdk.validatePassword(await credentials.validPasswordObject())).toThrow(PowerAuthErrorCode.authenticationError);

    // back to original
    await expect(sdk.changePassword(await credentials.invalidPasswordObject(), await credentials.validPasswordObject())).toSucceed();
    await expect(sdk.validatePassword(await credentials.validPasswordObject())).toSucceed();
    await expect(sdk.validatePassword(await credentials.invalidPasswordObject())).toThrow(PowerAuthErrorCode.authenticationError);
  }

  Future<void> testWrongPassword() async {
    var status = await sdk.fetchActivationStatus();
    final maxFailCount = status.maxFailCount;
    for (var i = 1; i <= maxFailCount; i++) {
      await expect(status.state).toBe(PowerAuthActivationState.active);
      await expect(sdk.validatePassword(await credentials.invalidPasswordObject())).toThrow(PowerAuthErrorCode.authenticationError);
      status = await sdk.fetchActivationStatus();
      expect(status.failCount).toBe(i);
      expect(status.remainingAttempts).toBe(maxFailCount - i);
    }
    await expect(status.state).toBe(PowerAuthActivationState.blocked);
    await expect(status.remainingAttempts).toBe(0);
  }

  Future<void> testReuseUsedPasswordObject() async {
    final pValid = await credentials.validPasswordObject();
    final pInvalid = await credentials.invalidPasswordObject();

    await expect(sdk.changePassword(pValid, pInvalid)).toSucceed();
    await expect(sdk.validatePassword(pInvalid)).toThrow(PowerAuthErrorCode.invalidNativeObject);
  }

  Future<void> testReusePasswordObjectInAuth() async {
    final pValid = await credentials.validPasswordObject(destroyOnUse: false);
    final pInvalid = await credentials.invalidPasswordObject(destroyOnUse: false);
    
    final validAuth = PowerAuthAuthentication.password(pValid);
    final invalidAuth = PowerAuthAuthentication.password(pInvalid);

    var header = await sdk.requestSignature(validAuth, 'POST', '/some/uriId', '{}');
    await expect((await helper.verifySignature('POST', '/some/uriId', header.value, '{}')).signatureValid).toBe(true);
    header = await sdk.requestSignature(validAuth, 'POST', '/some/uriId', '{}');
    await expect((await helper.verifySignature('POST', '/some/uriId', header.value, '{}')).signatureValid).toBe(true);
    
    header = await sdk.requestSignature(invalidAuth, 'POST', '/some/uriId', '{}');
    await expect((await helper.verifySignature('POST', '/some/uriId', header.value, '{}')).signatureValid).toBe(false);
    header = await sdk.requestSignature(invalidAuth, 'POST', '/some/uriId', '{}');
    await expect((await helper.verifySignature('POST', '/some/uriId', header.value, '{}')).signatureValid).toBe(false);
  }

  Future<void> testReuseUsedPasswordObjectInAuth() async {
    final pValid = await credentials.validPasswordObject();
    final pInvalid = await credentials.invalidPasswordObject();
    
    final validAuth = PowerAuthAuthentication.password(pValid);
    final invalidAuth = PowerAuthAuthentication.password(pInvalid);

    var header = await sdk.requestSignature(validAuth, 'POST', '/some/uriId', '{}');
    await expect((await helper.verifySignature('POST', '/some/uriId', header.value, '{}')).signatureValid).toBe(true);
    await expect(sdk.requestSignature(validAuth, 'POST', '/some/uriId', '{}')).toThrow(PowerAuthErrorCode.invalidNativeObject);
    
    header = await sdk.requestSignature(invalidAuth, 'POST', '/some/uriId', '{}');
    await expect((await helper.verifySignature('POST', '/some/uriId', header.value, '{}')).signatureValid).toBe(false);
    await expect(sdk.requestSignature(invalidAuth, 'POST', '/some/uriId', '{}')).toThrow(PowerAuthErrorCode.invalidNativeObject);
  }
}