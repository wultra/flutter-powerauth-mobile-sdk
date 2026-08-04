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

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/suites/test_suite.dart';

Uint8List _utf8Bytes(String value) => Uint8List.fromList(utf8.encode(value));

class PowerAuthBiometricsTests extends TestSuiteWithActivation {
  @override
  PowerAuthBiometryConfiguration get biometryConfiguration =>
      PowerAuthBiometryConfiguration(authenticateOnBiometricKeySetup: false);

  @override
  List<Future<void> Function()> getTests() => [testAddRemoveBiometryFactor];

  Future<void> androidTestCreateActivationWithRSABiometryKey() async {
    final activatioData = await helper.createActivation(autoCommit: true);
    final activation = PowerAuthActivation.fromActivationCode(
      activationCode: activatioData.activationCode,
      name: "Test",
    );
    await expect(await sdk.createActivation(activation)).toSucceed();
    final persistAuth = PowerAuthAuthentication.persistWithPasswordAndBiometry(
      password: await credentials.validPasswordObject(),
      biometricPrompt: PowerAuthBiometricPrompt(
        promptTitle: "Pls",
        promptMessage: "Persist data pls",
      ),
    );
    await expect(sdk.persistActivation(persistAuth)).toSucceed();
    await expect(sdk.hasBiometryFactor()).toBe(true);
  }

  Future<void> testAddRemoveBiometryFactor() async {
    await helper.prepareActiveActivation(
      await credentials.validPasswordObject(),
    );
    await expect(sdk.hasBiometryFactor()).toBe(false);
    var status = await sdk.getBiometricStatus();
    await expect(status.isBiometricFactorConfigured).toBe(false);
    await expect(status.isAuthenticationWithBiometricsAvailable).toBe(false);

    await expect(
      sdk.authenticationHeaderForRequestWithBody(
        credentials.biometry(),
        'POST',
        '/some/biometry',
        _utf8Bytes('{}'),
      ),
    ).toThrow(PowerAuthErrorCode.biometryNotConfigured);

    await expect(
      sdk.addBiometryFactor(await credentials.validPasswordObject()),
    ).toSucceed();
    await expect(sdk.hasBiometryFactor()).toBe(true);
    status = await sdk.getBiometricStatus();
    await expect(status.isBiometricFactorConfigured).toBe(true);
    await expect(
      await sdk.isAuthenticationWithBiometricsAvailable(),
    ).toBe(status.isAuthenticationWithBiometricsAvailable);

    await expect(sdk.removeBiometryFactor()).toSucceed();
    await expect(sdk.hasBiometryFactor()).toBe(false);
    status = await sdk.getBiometricStatus();
    await expect(status.isBiometricFactorConfigured).toBe(false);
    await expect(status.isAuthenticationWithBiometricsAvailable).toBe(false);
  }
}
