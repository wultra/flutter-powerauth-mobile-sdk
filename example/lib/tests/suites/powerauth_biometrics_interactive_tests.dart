/*
 * Copyright 2025 Wultra s.r.o.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:io';

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/suites/test_suite.dart';

class PowerauthBiometricsInteractiveTests extends TestSuiteWithActivation {

  @override
  List<Future<void> Function()> getTests() =>  [
    testBiometricSignature,
    testCreateActivationWithSymmetricKey,
    testGroupedBiometricAuthentication,
    testRemoveActivationWithBiometry,
    testCancelBiometry,
    testFailedBiometry,
    iosTestFallbackButton
  ];

  @override
  // ignore: overridden_fields
  bool isInteractive = true;

  Future<void> testCreateActivationWithSymmetricKey() async {
    final activationData = await helper.createActivation();
    final activation = PowerAuthActivation.fromActivationCode(activationCode: activationData.activationCode, name: "Test");
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
    await showPrompt("using auth for the first time");
    await expect(sdk.tokenStore.requestAccessToken(tokenName, auth)).toBeDefined();
    await expect(sdk.tokenStore.removeAccessToken(tokenName)).toSucceed();
    await showPrompt("using auth for the second time");
    // Try to reuse already used auth object
    await expect(sdk.tokenStore.requestAccessToken(tokenName, auth)).toThrow(PowerAuthErrorCode.invalidNativeObject);
  }

  Future<void> testGroupedBiometricAuthentication() async {

    await helper.prepareActiveActivation(await credentials.validPasswordObject(), setupBiometry: true);

    await expect(sdk.hasBiometryFactor()).toBe(true);
    await showPrompt('Please authenticate for group operation.');
    await sdk.groupedBiometricAuthentication(credentials.biometry(), (reusableAuth) async {
      //
      await showPrompt('Biometric dialog should not be displayed.', duration: UserPromptDuration.quick);
      // Calculate signature 
      var data = '{}';
      var uriId = '/some/uriId';
      var header = await sdk.requestSignature(reusableAuth, 'POST', uriId, data);
      // Verify signature
      var result = await helper.verifySignature("POST", uriId, header.value, data);
      await expect(result.signatureValid).toBe(true);
      //
      await showPrompt('Biometric dialog should not be displayed.', duration: UserPromptDuration.quick);
      // Calculate yet another signature and verify
      data = '{"value":true}';
      uriId = '/another/uriId';

      header = await sdk.requestSignature(reusableAuth, 'POST', uriId, data);
      result = await helper.verifySignature("POST", uriId, header.value, data);
      await expect(result.signatureValid).toBe(true);

      await showPrompt('Biometric dialog should not be displayed.', duration: UserPromptDuration.quick);
      // Calculate yet another signature and verify
      data = '{"value":false}';
      uriId = '/another/uriId';

      header = await sdk.requestSignature(reusableAuth, 'POST', uriId, data);
      result = await helper.verifySignature("POST", uriId, header.value, data);
      await expect(result.signatureValid).toBe(true);

      // Now sleep for 10 seconds

      await showPrompt('Sleeping for 10 s....', duration: UserPromptDuration.quick);
      await this.sleep(10_000);

      await showPrompt('Biometric dialog should be displayed again.');

      // Calculate yet another signature and verify
      data = '{"value":false, "something":true}';
      uriId = '/another/uriId';

      header = await sdk.requestSignature(reusableAuth, 'POST', uriId, data);
      result = await helper.verifySignature("POST", uriId, header.value, data);
      await expect(result.signatureValid).toBe(true);

      await showPrompt('Biometric dialog should not be displayed again.', duration: UserPromptDuration.quick);
      // Calculate yet another signature and verify
      data = '{"value":false}';
      uriId = '/another/uriId';

      header = await sdk.requestSignature(reusableAuth, 'POST', uriId, data);
      result = await helper.verifySignature("POST", uriId, header.value, data);
      await expect(result.signatureValid).toBe(true);
    });
  }

  Future<void> testRemoveActivationWithBiometry() async {
    await helper.prepareActiveActivation(await credentials.validPasswordObject(), setupBiometry: true);
    await expect(sdk.hasBiometryFactor()).toBe(true);
    await showPrompt('Authenticate to remove activation');
    await sdk.removeActivationWithAuthentication(credentials.biometry());
  }
    
  Future<void> testCancelBiometry() async {
    if (await _isFaceID()) {
      await showPrompt('This test is not supported on FaceID');
      return;
    }
    await helper.prepareActiveActivation(await credentials.validPasswordObject(), setupBiometry: true);
    await expect(sdk.hasBiometryFactor()).toBe(true);
    await showPrompt('Please CANCEL authentication dialog');
    final auth = PowerAuthAuthentication.biometry(biometricPrompt: PowerAuthBiometricPrompt(promptMessage: "Please CANCEL this dialog", promptTitle: "Please cancel", cancelButtonTitle: "super cancel"));
    await expect(sdk.requestSignature(auth, 'POST', '/some/uriId', '{}')).toThrow(PowerAuthErrorCode.biometryCancel);
  }

  Future<void> testFailedBiometry() async {
    if (await _isFaceID()) {
      await showPrompt('This test is not supported on FaceID');
      return;
    }
    await helper.prepareActiveActivation(await credentials.validPasswordObject(), setupBiometry: true);
    await expect(sdk.hasBiometryFactor()).toBe(true);
    await showPrompt('Please FAIL authentication dialog');
    
    final auth = PowerAuthAuthentication.biometry(biometricPrompt: PowerAuthBiometricPrompt(promptTitle: "Please fail", promptMessage: "Please use wrong biometry to fail"));
    // At biometry fail, the fake key is generated and the signature will be invalid
    final uriId = '/some/failed/uriId';
    final body = '{ failedApi: true }';
    final header = await sdk.requestSignature(auth, 'POST', uriId, body);
    final result = await helper.verifySignature("POST", uriId, header.value, body);
    await expect(result.signatureValid).toBe(false);
  }

  Future<void> iosTestFallbackButton() async {
    if (Platform.isAndroid) return;
    await helper.prepareActiveActivation(await credentials.validPasswordObject(), setupBiometry: true);
    await expect(sdk.hasBiometryFactor()).toBe(true);
    await showPrompt('Please FAIL authentication and use fallback button');
    final auth = PowerAuthAuthentication.biometry(biometricPrompt: PowerAuthBiometricPrompt(promptTitle: "Please fail", promptMessage: "Fail and then click the fallback button", fallbackButtonTitle: 'Fallback button'));
    await expect(sdk.requestSignature(auth, 'POST', '/some/uriId', '{}')).toThrow(PowerAuthErrorCode.biometryFallback);
  }

  Future<bool> _isFaceID() async {
    return !Platform.isAndroid && (await PowerAuth.getBiometryInfo()).biometryType == PowerAuthBiometryType.face;
  }
}