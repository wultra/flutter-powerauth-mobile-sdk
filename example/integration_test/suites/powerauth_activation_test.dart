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
  group('Activation tests', () {
    late IntegrationHelper helper;
    late PowerAuth sdk;
    late ActivationCredentials credentials;

    setUp(() async {
      sdk = PowerAuth(IntegrationHelper.randomString(30));
      helper = IntegrationHelper(sdk);
      await helper.configure();

      credentials = ActivationCredentials();
    });

    tearDown(() async {
      await helper.cleanup();
    });

    Future<void> runFailingMethodsDuringActivation(
      String stage,
      PowerAuthErrorCode expectedFetchError,
      PowerAuthErrorCode expectedError,
    ) async {
      // Fetch has a slighgtly different error handling, so it needs a different error code than other API function.
      await expectLater(
        sdk.fetchActivationStatus(),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            expectedFetchError,
          ),
        ),
      );
      await expectLater(
        sdk.removeActivationWithAuthentication(
          await credentials.invalidKnowledge(),
        ),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            expectedError,
          ),
        ),
      );
      await expectLater(
        sdk.requestGetSignature(
          await credentials.knowledge(),
          '/some/uriid',
          null,
        ),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            expectedError,
          ),
        ),
      );
      await expectLater(
        sdk.requestSignature(
          await credentials.knowledge(),
          'POST',
          '/some/uriid',
        ),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            expectedError,
          ),
        ),
      );
      await expectLater(
        sdk.changePassword(
          await credentials.validPasswordObject(),
          await credentials.invalidPasswordObject(),
        ),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            expectedError,
          ),
        ),
      );
      await expectLater(
        sdk.addBiometryFactor(
          await credentials.validPasswordObject(),
          PowerAuthBiometricPrompt(promptMessage: "desc"),
        ),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            expectedError,
          ),
        ),
      );

      await expectLater(
        sdk.fetchEncryptionKey(await credentials.knowledge(), 99),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            expectedError,
          ),
        ),
      );
      await expectLater(
        sdk.signDataWithDevicePrivateKey(await credentials.knowledge(), 'Data'),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            expectedError,
          ),
        ),
      );
      await expectLater(
        sdk.validatePassword(await credentials.validPasswordObject()),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            expectedError,
          ),
        ),
      );

      expect(
        await sdk.verifyServerSignedData('c2lnbmF0dXJl', 'c2lnbmF0dXJl', false),
        isFalse,
      );
      await expectLater(
        sdk.removeBiometryFactor(),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.biometryNotConfigured,
          ),
        ),
      );
      await expectLater(
        sdk.offlineSignature(
          await credentials.knowledge(),
          '/some/uriid',
          'MDEyMzQ1Njc=',
          null,
        ),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.missingActivation,
          ),
        ),
      );
    }

    Future<void> createActivationTest(bool useSignature) async {
      expect(await sdk.canStartActivation(), true);
      expect(await sdk.hasPendingActivation(), false);
      expect(await sdk.hasValidActivation(), false);
      expect(await sdk.getActivationIdentifier(), isNull);
      expect(await sdk.getActivationFingerprint(), isNull);
      expect(await sdk.getExternalPendingOperation(), isNull);

      await runFailingMethodsDuringActivation(
        'BEGIN',
        PowerAuthErrorCode.missingActivation,
        PowerAuthErrorCode.missingActivation,
      );
      await expectLater(
        sdk.persistActivation(await credentials.invalidKnowledge()),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.invalidActivationState,
          ),
        ),
      );

      final activationData = await helper.createActivation(autoCommit: false);
      final code =
          useSignature
              ? "${activationData.activationCode}#${activationData.activationCodeSignature}"
              : activationData.activationCode;
      final activation = PowerAuthActivation.fromActivationCode(
        activationCode: code,
        name: 'Flutter SDK Test',
      );
      final result = await sdk.createActivation(activation);
      expect(result, isNotNull);
      expect(result.activationFingerprint, isNotNull);

      await runFailingMethodsDuringActivation(
        'AFTER_CREATE',
        PowerAuthErrorCode.pendingActivation,
        PowerAuthErrorCode.missingActivation,
      );
      await expectLater(
        sdk.createActivation(activation),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.invalidActivationState,
          ),
        ),
      );
      expect(await sdk.canStartActivation(), false);
      expect(await sdk.hasPendingActivation(), true);
      expect(await sdk.hasValidActivation(), false);

      var activationId = await sdk.getActivationIdentifier();
      var activationFingerprint = await sdk.getActivationFingerprint();
      expect(activationId, isNotNull);
      expect(activationFingerprint, isNotNull);

      var activationDetail = await helper.getRegistrationDetail();

      expect(activationDetail.activationFingerprint, isNotNull);
      expect(activationId, activationDetail.registrationId);
      expect(result.activationFingerprint, activationFingerprint);
      expect(
        result.activationFingerprint,
        activationDetail.activationFingerprint,
      );
      await helper.commitActivation();
      await sdk.persistActivation(await credentials.knowledge());

      activationId = await sdk.getActivationIdentifier();
      activationFingerprint = await sdk.getActivationFingerprint();
      expect(activationId, isNotNull);
      expect(activationFingerprint, isNotNull);

      expect(await sdk.canStartActivation(), false);
      expect(await sdk.hasPendingActivation(), false);
      expect(await sdk.hasValidActivation(), true);

      activationDetail = await helper.getRegistrationDetail();
      expect(
        activationDetail.activationFingerprint,
        isNull,
      ); // backend no longer returns fingerprint
      expect(activationId, activationDetail.registrationId);
      expect(result.activationFingerprint, activationFingerprint);

      final state = (await sdk.fetchActivationStatus()).state;

      if (state != PowerAuthActivationState.active) {
        fail("State should be ACTIVE but is $state");
      }

      expect(await sdk.canStartActivation(), false);
      expect(await sdk.hasPendingActivation(), false);
      expect(await sdk.hasValidActivation(), true);

      await expectLater(
        sdk.createActivation(activation),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.invalidActivationState,
          ),
        ),
      );
      await expectLater(
        sdk.persistActivation(await credentials.invalidKnowledge()),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.invalidActivationState,
          ),
        ),
      );

      expect(await sdk.canStartActivation(), false);
      expect(await sdk.hasPendingActivation(), false);
      expect(await sdk.hasValidActivation(), true);
    }

    test('testCreateActivationWithBareCode', () async {
      await createActivationTest(false);
    });

    test('testCreateActivationWithSignedCode', () async {
      await createActivationTest(true);
    });

    test('testFetchActivationStatus', () async {
      await helper.prepareActiveActivation(
        await credentials.validPasswordObject(),
      );

      expect(await sdk.hasValidActivation(), true);

      var status = await sdk.fetchActivationStatus();
      expect(status.state, PowerAuthActivationState.active);
      await helper.changeActivation(ActivationChange.block);

      status = await sdk.fetchActivationStatus();
      expect(status.state, PowerAuthActivationState.blocked);

      await helper.changeActivation(ActivationChange.unblock);
      status = await sdk.fetchActivationStatus();
      expect(status.state, PowerAuthActivationState.active);

      await helper.removeRegistration();
      status = await sdk.fetchActivationStatus();
      expect(status.state, PowerAuthActivationState.removed);
      expect(await sdk.hasValidActivation(), true);

      await sdk.removeActivationLocal();
      expect(await sdk.hasValidActivation(), false);
    });

    test('testActivationRemove', () async {
      await helper.prepareActiveActivation(
        await credentials.validPasswordObject(),
      );
      await sdk.removeActivationWithAuthentication(
        await credentials.knowledge(),
      );
      expect(await sdk.hasValidActivation(), false);
    });

    test('testVerifyActivationQrCode', () async {
      expect(await sdk.canStartActivation(), true);
      await helper.createActivation();
      expect(await helper.createdActivation?.activationCode, isNotNull);
      expect(
        await helper.createdActivation?.activationCodeSignature,
        isNotNull,
      );
    });

    test('testOIDCActivationData', () async {
      expect(await sdk.canStartActivation(), true);

      final oidcParameters = PowerAuthOIDCParameters(
        providerId: "exampleProvider",
        code: "ABCDEFG1234567890",
        nonce: "K1mP3rT9bQ8lV6zN7sW2xY4dJ5oU0fA1gH29o",
        codeVerifier:
            "G3hsI1KZX1o~K0p-5lT3F7yZ4bC8dE2jX9aQ6nO2rP3uS7wT5mV8jW1oY6xB3sD09tR4vU3qM1nG7kL6hV5wY2pJ0aF3eK9dQ8xN4mS2zB7oU5tL1cJ3vX6yP8rE2wO9n",
      );

      final activation = PowerAuthActivation.fromOIDC(
        oidcParameters: oidcParameters,
        name: 'Flutter SDK OIDC Test',
        extras: 'Some extras',
        customAttributes: {'key1': 'value1', 'key2': 2},
      );
      await expectLater(
        sdk.createActivation(activation),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.responseError,
          ),
        ),
      );

      final oidcParametersWithoutCodeVerifier = PowerAuthOIDCParameters(
        providerId: "exampleProvider",
        code: "ABCDEFG1234567890",
        nonce: "K1mP3rT9bQ8lV6zN7sW2xY4dJ5oU0fA1gH29o",
      );

      final activation2 = PowerAuthActivation.fromOIDC(
        oidcParameters: oidcParametersWithoutCodeVerifier,
        name: 'Flutter SDK OIDC Test',
      );

      // We expect an error here from the server, because OIDC data are made up.
      // If the oidc object would be invalid, then the error would be different.
      await expectLater(
        sdk.createActivation(activation2),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.responseError,
          ),
        ),
      );

      final oidcParametersInvalid = PowerAuthOIDCParameters(
        providerId: "exampleProvider",
        code: "", // empty - invalid code
        nonce: "K1mP3rT9bQ8lV6zN7sW2xY4dJ5oU0fA1gH29o",
      );

      final activation3 = PowerAuthActivation.fromOIDC(
        oidcParameters: oidcParametersInvalid,
        name: 'Flutter SDK OIDC Test',
      );
      await expectLater(
        sdk.createActivation(activation3),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.invalidActivationObject,
          ),
        ),
      );
    });
  });
}
