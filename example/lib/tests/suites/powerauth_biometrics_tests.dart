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

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/suites/test_suite.dart';

class PowerAuthBiometricsTests extends TestSuiteWithActivation {

  @override
  List<Future<void> Function()> getTests() => [/*androidTestCreateActivationWithRSABiometryKey,*/testAddRemoveBiometryFactor];

  Future<void> androidTestCreateActivationWithRSABiometryKey() async {
    final activatioData = await helper.createActivation(autoCommit: true);
    final activation = PowerAuthActivation.fromActivationCode(activationCode: activatioData.activationCode, name: "Test");
    await expect(await sdk.createActivation(activation)).toSucceed();
    final persistAuth = PowerAuthAuthentication.persistWithPasswordAndBiometry(password: await credentials.validPasswordObject(), biometricPrompt: PowerAuthBiometricPrompt(promptMessage: "Persist data pls"));
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