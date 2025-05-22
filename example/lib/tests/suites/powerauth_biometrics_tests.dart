import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/suites/test_suite.dart';

class PowerauthBiometricsTests extends TestSuiteWithActivation {

  @override
  List<Future<void> Function()> getTests() => [/*androidTestCreateActivationWithRSABiometryKey,*/testAddRemoveBiometryFactor];

  Future<void> androidTestCreateActivationWithRSABiometryKey() async {
    final activatioData = await helper.createActivation(autoCommit: true);
    final activation = PowerAuthActivation.fromActivationCode(activationCode: activatioData.activationCode, name: "Test");
    await expect(await sdk.createActivation(activation)).toSucceed();
    final persistAuth = PowerAuthAuthentication.persistWithPasswordAndBiometry(password: await credentials.validPasswordObject());
    await expect(sdk.persistActivation(persistAuth)).toSucceed();
    await expect(sdk.hasBiometryFactor()).toBe(true);
  }

  Future<void> testAddRemoveBiometryFactor() async {
    
    await helper.prepareActiveActivation(await credentials.validPasswordObject());
    await expect(sdk.hasBiometryFactor()).toBe(false);

    await expect(sdk.requestSignature(credentials.biometry(), 'POST', '{}', '/some/biometry')).toThrow(PowerAuthErrorCode.biometryNotConfigured);

    await expect(sdk.addBiometryFactor(await credentials.validPasswordObject())).toSucceed();
    await expect(sdk.hasBiometryFactor()).toBe(true);

    await expect(sdk.removeBiometryFactor()).toSucceed();
    await expect(sdk.hasBiometryFactor()).toBe(false);
  }
}