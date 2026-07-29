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
import '../utils/activation_credentials.dart';
import '../utils/integration_helper.dart';

import 'package:flutter_test/flutter_test.dart';

main() {
  group('Biometrics automated tests', () {
    late IntegrationHelper helper;
    late PowerAuth sdk;
    late ActivationCredentials credentials;

    setUp(() async {
      sdk = PowerAuth(IntegrationHelper.randomString(30));
      helper = IntegrationHelper(sdk);

      // Force automation-friendly configuration
      await helper.configure(automatedTesting: true);

      credentials = ActivationCredentials();
    });

    tearDown(() async {
      await helper.cleanup();
    });

    test('persist activation with biometry', () async {
      final activationData = await helper.createActivation(autoCommit: true);
      final activation = PowerAuthActivation.fromActivationCode(
        activationCode: activationData.activationCode,
        name: 'Automated',
      );
      await expectLater(sdk.createActivation(activation), completes);

      final password = await credentials.validPasswordObject();
      final persistAuth =
          PowerAuthAuthentication.persistWithPasswordAndBiometry(
            password: password,
            biometricPrompt: PowerAuthBiometricPrompt(
              promptMessage: 'Empty prompt since no UI',
            ),
          );
      await expectLater(sdk.persistActivation(persistAuth), completes);

      expect(await sdk.hasBiometryFactor(), isFalse);
    }, skip: Platform.isAndroid);

    test('addbiometry factor', () async {
      // Prepare activation without biometry factor
      await helper.prepareActiveActivation(
        await credentials.validPasswordObject(),
        setupBiometry: false,
      );

      expect(await sdk.hasBiometryFactor(), isFalse);

      // Biometry not available in runner so adding a factor should fail
      final systemStatus = (await sdk.getBiometricStatus()).systemStatus;
      final expectedCode =
          Platform.isIOS
              ? PowerAuthErrorCode.biometryNotAvailable
              : switch (systemStatus) {
                PowerAuthBiometryStatus.notSupported =>
                  PowerAuthErrorCode.biometryNotSupported,
                PowerAuthBiometryStatus.notEnrolled =>
                  PowerAuthErrorCode.biometryNotEnrolled,
                PowerAuthBiometryStatus.notAvailable =>
                  PowerAuthErrorCode.biometryNotAvailable,
                PowerAuthBiometryStatus.lockout =>
                  PowerAuthErrorCode.biometryLockout,
                PowerAuthBiometryStatus.ok =>
                  throw StateError(
                    'This runner reports available biometry; use the device suite instead.',
                  ),
              };
      await expectLater(
        sdk.addBiometryFactor(await credentials.validPasswordObject()),
        throwsA(
          isA<PowerAuthException>().having(
            (error) => error.code,
            'code',
            expectedCode,
          ),
        ),
      );
    }, skip: Platform.isAndroid);

    test(
      'configured instance without activation has unavailable biometry',
      () async {
        expect(await sdk.hasValidActivation(), isFalse);
        expect(await sdk.hasBiometryFactor(), isFalse);

        final status = await sdk.getBiometricStatus();
        final available = await sdk.isAuthenticationWithBiometricsAvailable();
        expect(status.isBiometricFactorConfigured, isFalse);
        expect(status.isAuthenticationWithBiometricsAvailable, isFalse);
        expect(available, status.isAuthenticationWithBiometricsAvailable);
        if (status.systemStatus == PowerAuthBiometryStatus.ok) {
          expect(
            available,
            isFalse,
            reason:
                'System biometry alone is insufficient without activation and factor.',
          );
        }
      },
    );
  });
}
