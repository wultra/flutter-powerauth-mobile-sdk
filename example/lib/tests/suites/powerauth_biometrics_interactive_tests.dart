import 'dart:io';

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/suites/test_suite.dart';

class PowerauthBiometricsInteractiveTests extends TestSuiteWithActivation {

  @override
  List<Future<void> Function()> getTests() =>  [
    testBiometricSignature,
    testCreateActivationWithSymmetricKey
  ];

  @override
  bool isInteractive = true;

  Future<void> testCreateActivationWithSymmetricKey() async {
    final activatioData = await helper.createActivation();
    final activation = PowerAuthActivation.fromActivationCode(activationCode: activatioData.activationCode, name: "Test");
    await expect(sdk.createActivation(activation)).toSucceed();
    // Now persist activation with a legacy authentication

    if (Platform.isAndroid) await showPrompt('Authenticate to create activation with biometry');

    final password = await credentials.validPasswordObject();
    final persistAuth = PowerAuthAuthentication.persistWithPasswordAndBiometry(
      password: password, 
      biometricPrompt: PowerAuthBiometricPrompt(
        promptTitle: 'Authenticate with biometry',
        promptMessage: 'Authenticate to create activation with biometry'
      )
    );
    await expect(sdk.persistActivation(persistAuth)).toSucceed();

    // Now calculate some signature
    await showPrompt('Authenticate to calculate signature with symmetric key');

    final auth = PowerAuthAuthentication.biometry(
      biometricPrompt: PowerAuthBiometricPrompt(
        promptTitle: 'Authenticate',
        promptMessage: 'Please authenticate with biometry'
      )
    );
    await expect(sdk.tokenStore.requestAccessToken('biometric-token', auth)).toSucceed();
    await expect(sdk.tokenStore.removeAccessToken('biometric-token')).toSucceed();

    // Now remove biometry key
    await expect(sdk.removeBiometryFactor()).toSucceed();

    // And add it again
    if (Platform.isAndroid) await showPrompt('Authenticate to add biometric factor again');
    await expect(sdk.addBiometryFactor(await credentials.validPasswordObject())).toSucceed();
  }

  Future<void> testBiometricSignature() async {

    await helper.prepareActiveActivation(await credentials.validPasswordObject(), setupBiometry: true);

    await expect(sdk.hasBiometryFactor()).toBe(true);
    await showPrompt('Please authenticate with biometry to request access token');
    final auth = PowerAuthAuthentication.biometry(
      biometricPrompt: PowerAuthBiometricPrompt(
        promptMessage: 'Please authenticate with biometry',
        promptTitle: 'Authenticate',
      )
    );
    final tokenName = 'biometric-token';
    await showPrompt("using auth for the frist time");
    await expect(sdk.tokenStore.requestAccessToken(tokenName, auth)).toBeDefined();
    await expect(sdk.tokenStore.removeAccessToken(tokenName)).toSucceed();
    await showPrompt("using auth for the second time");
    // Try to reuse already used auth object
    await expect(sdk.tokenStore.requestAccessToken(tokenName, auth)).toThrow(PowerAuthErrorCode.invalidNativeObject);
  }

    // async testGroupedBiometricAuthentication() {
    //     await expect(sdk.hasBiometryFactor()).toBe(true)
    //     await this.showPrompt('Please authenticate for group operation.')
    //     await sdk.groupedBiometricAuthentication(this.credentials.biometry, async reusableAuth => {
    //         //
    //         await this.showPrompt('Biometric dialog should not be displayed.', UserPromptDuration.QUICK)
    //         // Calculate signature 
    //         let data = '{}'
    //         let uriId = '/some/uriId'
    //         let header = await sdk.requestSignature(reusableAuth, 'POST', uriId, data)
    //         // Verify signature
    //         let result = await this.helper.signatureHelper.verifyOnlineSignature('POST', uriId, data, header.value)
    //         await expect(result).toBe(true)
    //         //
    //         await this.showPrompt('Biometric dialog should not be displayed.', UserPromptDuration.QUICK)
    //         // Calculate yet another signature and verify
    //         data = '{"value":true}'
    //         uriId = '/another/uriId'

    //         header = await sdk.requestSignature(reusableAuth, 'POST', uriId, data)
    //         result = await this.helper.signatureHelper.verifyOnlineSignature('POST', uriId, data, header.value)
    //         await expect(result).toBe(true)

    //         await this.showPrompt('Biometric dialog should not be displayed.', UserPromptDuration.QUICK)
    //         // Calculate yet another signature and verify
    //         data = '{"value":false}'
    //         uriId = '/another/uriId'

    //         header = await sdk.requestSignature(reusableAuth, 'POST', uriId, data)
    //         result = await this.helper.signatureHelper.verifyOnlineSignature('POST', uriId, data, header.value)
    //         await expect(result).toBe(true)

    //         // Now sleep for 10 seconds

    //         await this.sleepWithProgress(10000)

    //         await this.showPrompt('Biometric dialog should be displayed again.')

    //         // Calculate yet another signature and verify
    //         data = '{"value":false, "something":true}'
    //         uriId = '/another/uriId'

    //         header = await sdk.requestSignature(reusableAuth, 'POST', uriId, data)
    //         result = await this.helper.signatureHelper.verifyOnlineSignature('POST', uriId, data, header.value)
    //         await expect(result).toBe(true)

    //         await this.showPrompt('Biometric dialog should not be displayed again.', UserPromptDuration.QUICK)
    //         // Calculate yet another signature and verify
    //         data = '{"value":false}'
    //         uriId = '/another/uriId'

    //         header = await sdk.requestSignature(reusableAuth, 'POST', uriId, data)
    //         result = await this.helper.signatureHelper.verifyOnlineSignature('POST', uriId, data, header.value)
    //         await expect(result).toBe(true)
    //     })
    // }

    // async testRemoveActivationWithBiometry() {
    //     await expect(sdk.hasBiometryFactor()).toBe(true)
    //     await this.showPrompt('Authenticate to remove activation')
    //     await sdk.removeActivationWithAuthentication(this.credentials.biometry)
    // }
    
    // async testCancelBiometry() {
    //     await expect(sdk.hasBiometryFactor()).toBe(true)
    //     await this.showPrompt('Please CANCEL authentication dialog')
    //     final auth = PowerAuthAuthentication.biometry({promptTitle: "Please cancel", promptMessage: "Please CANCEL this dialog", cancelButton: "super cancel"})
    //     await await expect(async () => sdk.requestSignature(auth, 'POST', '/some/uriId', '{}')).toThrow({ errorCode: PowerAuthErrorCode.BIOMETRY_CANCEL })
    // }

    // async testFailedBiometry() {
    //     await expect(sdk.hasBiometryFactor()).toBe(true)
    //     final isFaceId = !this.isAndoid && (await sdk.getBiometryInfo()).biometryType == PowerAuthBiometryType.FACE
    //     if (isFaceId) {
    //         await this.showPrompt('This test is not supported on FaceID')
    //         return
    //     }

    //     await this.showPrompt('Please FAIL authentication dialog')
        
    //     final auth = PowerAuthAuthentication.biometry({promptTitle: "Please fail", promptMessage: "Please use wrong biometry to fail"})
    //     // At biometry fail, the fake key is generated and the signature will be invalid
    //     let uriId = '/some/failed/uriId'
    //     let body = '{ failedApi: true }'
    //     final header = await sdk.requestSignature(auth, 'POST', uriId, body)
    //     final result = await this.helper.signatureHelper.verifyOnlineSignature('POST', uriId, body, header.value)
    //     await expect(result).toBe(false)
    // }

    // async iosTestFallbackToPasscode() {
    //     await expect(sdk.hasBiometryFactor()).toBe(true)
    //     await this.showPrompt('Please FAIL authentication and use device passcode')
    //     final auth = PowerAuthAuthentication.biometry({promptTitle: "Please fail", promptMessage: "Please use fallback to passcode"})
    //     // At biometry passcode fallback, everything should work properly
    //     let uriId = '/some/fallback/uriId'
    //     let body = '{ fallbackApi: true }'
    //     final header = await sdk.requestSignature(auth, 'POST', uriId, body)
    //     final result = await this.helper.signatureHelper.verifyOnlineSignature('POST', uriId, body, header.value)
    //     await expect(result).toBe(true)
    // }

    // async iosTestFallbackButton() {
    //     await expect(sdk.hasBiometryFactor()).toBe(true)
    //     await this.showPrompt('Please FAIL authentication and use fallback button')
    //     final auth = PowerAuthAuthentication.biometry({promptTitle: "Please fail", promptMessage: "Please use fallback to passcode", fallbackButton: 'fallback button'})
    //     await await expect(async () => sdk.requestSignature(auth, 'POST', '/some/uriId', '{}')).toThrow({ errorCode: PowerAuthErrorCode.BIOMETRY_FALLBACK })
    // }
}