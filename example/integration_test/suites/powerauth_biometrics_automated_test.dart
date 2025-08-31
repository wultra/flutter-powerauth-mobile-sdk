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

    test(
      'persist activation with password+biometry (no prompt expected)',
      () async {
        final activationData = await helper.createActivation(autoCommit: true);
        final activation = PowerAuthActivation.fromActivationCode(
          activationCode: activationData.activationCode,
          name: 'Automated',
        );
        expect(await sdk.createActivation(activation), isNot(throwsException));

        final password = await credentials.validPasswordObject();
        final persistAuth =
            PowerAuthAuthentication.persistWithPasswordAndBiometry(
              password: password,
              biometricPrompt: PowerAuthBiometricPrompt(
                promptMessage: 'No UI expected in automated mode',
              ),
            );
        await expectLater(sdk.persistActivation(persistAuth), completes);

        expect(await sdk.hasBiometryFactor(), isFalse);
      },
    );

    test('addbiometry factor', () async {
      // Prepare activation without biometry factor
      await helper.prepareActiveActivation(
        await credentials.validPasswordObject(),
        setupBiometry: false,
      );

      expect(await sdk.hasBiometryFactor(), isFalse);

      // Biometry not available in runner so adding a factor should fail
      await expectLater(
        sdk.addBiometryFactor(await credentials.validPasswordObject()),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            'code',
            PowerAuthErrorCode.biometryNotAvailable,
          ),
        ),
      );
    });

    test('get biometry info', () async {
      final info = await PowerAuth.getBiometryInfo();

      expect(info.isAvailable, isFalse);
      expect(info.canAuthenticate == PowerAuthBiometryStatus.ok, isFalse);
    });
  });
}
