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
import '../utils/object_cleanup_helper.dart';

import 'package:flutter_test/flutter_test.dart';

main() {
  group('Password tests', () {
    late ObjectCleanupHelper cleanupHelper;
    late IntegrationHelper helper;
    late PowerAuth sdk;
    late ActivationCredentials credentials;

    setUp(() async {
      cleanupHelper = ObjectCleanupHelper();

      sdk = PowerAuth(IntegrationHelper.randomString(30));
      helper = IntegrationHelper(sdk);
      await helper.configure();

      credentials = ActivationCredentials();
      await helper.prepareActiveActivation(
        await credentials.validPasswordObject(),
      );
    });

    tearDown(() async {
      await helper.cleanup();
      await cleanupHelper.dispose();
    });

    test('testValidatePassword', () async {
      await expectLater(
        sdk.validatePassword(await credentials.validPasswordObject()),
        completes,
      );
      await expectLater(
        sdk.validatePassword(await credentials.invalidPasswordObject()),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.authenticationError,
          ),
        ),
      );
    });

    test('testChangePassword', () async {
      await expectLater(
        sdk.changePassword(
          await credentials.validPasswordObject(),
          await credentials.invalidPasswordObject(),
        ),
        completes,
      );
      await expectLater(
        sdk.validatePassword(await credentials.invalidPasswordObject()),
        completes,
      );
      await expectLater(
        sdk.validatePassword(await credentials.validPasswordObject()),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.authenticationError,
          ),
        ),
      );
      await expectLater(
        sdk.changePassword(
          await credentials.invalidPasswordObject(),
          await credentials.validPasswordObject(),
        ),
        completes,
      );
      await expectLater(
        sdk.validatePassword(await credentials.validPasswordObject()),
        completes,
      );
      await expectLater(
        sdk.validatePassword(await credentials.invalidPasswordObject()),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.authenticationError,
          ),
        ),
      );
    });

    test('testWrongPassword', () async {
      var status = await sdk.fetchActivationStatus();
      final maxFailCount = status.maxFailCount;
      for (var i = 1; i <= maxFailCount; i++) {
        expect(status.state, PowerAuthActivationState.active);
        await expectLater(
          sdk.validatePassword(await credentials.invalidPasswordObject()),
          throwsA(
            isA<PowerAuthException>().having(
              (e) => e.code,
              "code",
              PowerAuthErrorCode.authenticationError,
            ),
          ),
        );

        status = await sdk.fetchActivationStatus();
        expect(status.failCount, i);
        expect(status.remainingAttempts, maxFailCount - i);
      }

      expect(status.state, PowerAuthActivationState.blocked);
      expect(status.remainingAttempts, 0);
    });

    test('testReuseUsedPasswordObject', () async {
      final pValid = await credentials.validPasswordObject();
      final pInvalid = await credentials.invalidPasswordObject();

      await expectLater(sdk.changePassword(pValid, pInvalid), completes);
      await expectLater(
        sdk.validatePassword(pInvalid),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.invalidNativeObject,
          ),
        ),
      );
    });

    test('testReusePasswordObjectInAuth', () async {
      final pValid = await credentials.validPasswordObject(destroyOnUse: false);
      final pInvalid = await credentials.invalidPasswordObject(
        destroyOnUse: false,
      );

      final validAuth = PowerAuthAuthentication.password(pValid);
      final invalidAuth = PowerAuthAuthentication.password(pInvalid);

      var header = await sdk.requestSignature(
        validAuth,
        'POST',
        '/some/uriId',
        '{}',
      );
      expect(
        (await helper.verifySignature(
          'POST',
          '/some/uriId',
          header.value,
          '{}',
        )).signatureValid,
        true,
      );
      header = await sdk.requestSignature(
        validAuth,
        'POST',
        '/some/uriId',
        '{}',
      );
      expect(
        (await helper.verifySignature(
          'POST',
          '/some/uriId',
          header.value,
          '{}',
        )).signatureValid,
        true,
      );

      header = await sdk.requestSignature(
        invalidAuth,
        'POST',
        '/some/uriId',
        '{}',
      );
      expect(
        (await helper.verifySignature(
          'POST',
          '/some/uriId',
          header.value,
          '{}',
        )).signatureValid,
        false,
      );
      header = await sdk.requestSignature(
        invalidAuth,
        'POST',
        '/some/uriId',
        '{}',
      );
      expect(
        (await helper.verifySignature(
          'POST',
          '/some/uriId',
          header.value,
          '{}',
        )).signatureValid,
        false,
      );
    });

    test('testReuseUsedPasswordObjectInAuth', () async {
      final pValid = await credentials.validPasswordObject();
      final pInvalid = await credentials.invalidPasswordObject();

      final validAuth = PowerAuthAuthentication.password(pValid);
      final invalidAuth = PowerAuthAuthentication.password(pInvalid);

      var header = await sdk.requestSignature(
        validAuth,
        'POST',
        '/some/uriId',
        '{}',
      );
      expect(
        (await helper.verifySignature(
          'POST',
          '/some/uriId',
          header.value,
          '{}',
        )).signatureValid,
        true,
      );
      expect(
        sdk.requestSignature(validAuth, 'POST', '/some/uriId', '{}'),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.invalidNativeObject,
          ),
        ),
      );

      header = await sdk.requestSignature(
        invalidAuth,
        'POST',
        '/some/uriId',
        '{}',
      );
      expect(
        (await helper.verifySignature(
          'POST',
          '/some/uriId',
          header.value,
          '{}',
        )).signatureValid,
        false,
      );
      expect(
        sdk.requestSignature(invalidAuth, 'POST', '/some/uriId', '{}'),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.invalidNativeObject,
          ),
        ),
      );
    });
  });
}
