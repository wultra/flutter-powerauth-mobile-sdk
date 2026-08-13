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
import '../utils/helper_functions.dart';
import '../utils/integration_helper.dart';

import '../utils/native_test.dart';

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
      PowerAuthErrorCode expectedFetchError,
      PowerAuthErrorCode expectedError,
      PowerAuthErrorCode expectedHeaderError,
      PowerAuthErrorCode expectedVerifyError,
    ) async {
      // Fetch has slightly different error handling, so it needs a different
      // error code than the other API functions.
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
        sdk.authenticationHeaderForRequestWithParams(
          await credentials.knowledge(),
          'GET',
          '/some/uriid',
          null,
        ),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            expectedHeaderError,
          ),
        ),
      );
      await expectLater(
        sdk.authenticationHeaderForRequestWithBody(
          await credentials.knowledge(),
          'POST',
          '/some/uriid',
        ),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            expectedHeaderError,
          ),
        ),
      );
      await expectLater(
        sdk.beginPasswordChange(await credentials.validPasswordObject()),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            expectedError,
          ),
        ),
      );
      await expectLater(
        sdk.fetchSecureVaultKey(
          await credentials.knowledge(),
          PowerAuthSecureVaultKeyId.knowledge,
        ),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            expectedHeaderError,
          ),
        ),
      );
      await expectLater(
        sdk.calculateDigitalSignature(
          await credentials.knowledge(),
          utf8Bytes('Data'),
          PowerAuthSignatureKeyId.deviceEc,
        ),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            expectedHeaderError,
          ),
        ),
      );
      await expectLater(
        sdk.verifyDigitalSignature(
          utf8Bytes('signature'),
          utf8Bytes('data'),
          PowerAuthSignatureKeyId.serverEc,
        ),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            expectedVerifyError,
          ),
        ),
      );
      await expectLater(
        sdk.removeBiometryFactor(),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            expectedError,
          ),
        ),
      );
    }

    Future<void> expectOfflineSignatureRejectedWithoutValidActivation() async {
      await expectLater(
        sdk
            .offlineSignature(
              await credentials.knowledge(),
              '/some/uriid',
              'MDEyMzQ1Njc=',
            )
            .timeout(const Duration(seconds: 10)),
        throwsPowerAuthCode(
          //platforms differ in error code for this case
          platformErrorCode(
            android: PowerAuthErrorCode.invalidActivationState,
            ios: PowerAuthErrorCode.missingActivation,
          ),
        )
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
        PowerAuthErrorCode.missingActivation,
        PowerAuthErrorCode.missingActivation,
        PowerAuthErrorCode.missingActivation,
        PowerAuthErrorCode.missingActivation,
      );
      await expectLater(
        sdk.persistActivation(await credentials.invalidPersistence()),
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
        //platforms differ in error code for this case
        platformErrorCode(
          android: PowerAuthErrorCode.missingActivation,
          ios: PowerAuthErrorCode.pendingActivation,
        ),
        PowerAuthErrorCode.missingActivation,
        PowerAuthErrorCode.invalidActivationState,
        PowerAuthErrorCode.wrongSignature,
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
      await sdk.persistActivation(await credentials.persistence());

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
        sdk.persistActivation(await credentials.invalidPersistence()),
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

    test(
      'offlineSignature without activation reports an error instead of hanging',
      () async {
        expect(await sdk.hasValidActivation(), false);
        expect(await sdk.hasPendingActivation(), false);

        await expectOfflineSignatureRejectedWithoutValidActivation();
      },
    );

    test(
      'offlineSignature with pending activation reports an error instead of hanging',
      () async {
        final activationData = await helper.createActivation(autoCommit: false);
        await sdk.createActivation(
          PowerAuthActivation.fromActivationCode(
            activationCode: activationData.activationCode,
            name: 'Flutter SDK Offline Signature Test',
          ),
        );

        expect(await sdk.hasValidActivation(), false);
        expect(await sdk.hasPendingActivation(), true);

        await expectOfflineSignatureRejectedWithoutValidActivation();
      },
    );

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
      expect(helper.createdActivation?.activationCode, isNotNull);
      expect(helper.createdActivation?.activationCodeSignature, isNotNull);
    });

    test('OIDC server rejection includes stable response details', () async {
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
        throwsPowerAuthServerError(PowerAuthErrorCode.networkError),
      );
    });

    test('OIDC without PKCE is accepted locally then rejected by server', () async {
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
        throwsPowerAuthServerError(PowerAuthErrorCode.networkError),
      );
    });

    test('locally invalid OIDC code does not make a server request', () async {
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
        throwsPowerAuthCode(
          //platforms differ in error code for this case
          platformErrorCode(
            android: PowerAuthErrorCode.invalidActivationData,
            ios: PowerAuthErrorCode.invalidActivationCode,
          ),
        ),
      );
    });
  });
}
