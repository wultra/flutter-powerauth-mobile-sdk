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

    Future<void> validatePassword(PowerAuthPassword password) async {
      final changeData = await sdk.beginPasswordChange(password);
      cleanupHelper.cleanup.add(changeData);
      await changeData.release();
    }

    Future<void> changePassword(
      PowerAuthPassword oldPassword,
      PowerAuthPassword newPassword,
    ) async {
      final changeData = await sdk.beginPasswordChange(oldPassword);
      cleanupHelper.cleanup.add(changeData);
      await sdk.finishPasswordChange(newPassword, changeData);
    }

    test('testBeginPasswordChangeValidatesPassword', () async {
      await validatePassword(await credentials.validPasswordObject());
      await expectLater(
        sdk.beginPasswordChange(await credentials.invalidPasswordObject()),
        throwsPowerAuthServerError(PowerAuthErrorCode.networkError),
      );
    });

    test('testTwoStepPasswordChange', () async {
      await changePassword(
        await credentials.validPasswordObject(),
        await credentials.invalidPasswordObject(),
      );
      await validatePassword(await credentials.invalidPasswordObject());
      await expectLater(
        sdk.beginPasswordChange(await credentials.validPasswordObject()),
        throwsPowerAuthServerError(PowerAuthErrorCode.networkError),
      );
      await changePassword(
        await credentials.invalidPasswordObject(),
        await credentials.validPasswordObject(),
      );
      await validatePassword(await credentials.validPasswordObject());
      await expectLater(
        sdk.beginPasswordChange(await credentials.invalidPasswordObject()),
        throwsPowerAuthServerError(PowerAuthErrorCode.networkError),
      );
    });

    test('testWrongPassword', () async {
      var status = await sdk.fetchActivationStatus();
      final maxFailCount = status.maxFailCount;
      for (var i = 1; i <= maxFailCount; i++) {
        expect(status.state, PowerAuthActivationState.active);
        await expectLater(
          validatePassword(await credentials.invalidPasswordObject()),
          throwsPowerAuthServerError(PowerAuthErrorCode.networkError),
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
      cleanupHelper.cleanup.addAll([pValid, pInvalid]);

      final changeData = await sdk.beginPasswordChange(pValid);
      cleanupHelper.cleanup.add(changeData);
      await sdk.finishPasswordChange(pInvalid, changeData);
      await expectLater(
        sdk.finishPasswordChange(
          await credentials.validPasswordObject(),
          changeData,
        ),
        throwsPowerAuthCode(PowerAuthErrorCode.invalidNativeObject),
      );
      await expectLater(
        pValid.isEmpty(),
        throwsPowerAuthCode(PowerAuthErrorCode.invalidNativeObject),
      );
      await expectLater(
        pInvalid.isEmpty(),
        throwsPowerAuthCode(PowerAuthErrorCode.invalidNativeObject),
      );
    });

    test('testReusePasswordObjectInAuth', () async {
      final pValid = await credentials.validPasswordObject(destroyOnUse: false);
      final pInvalid = await credentials.invalidPasswordObject(
        destroyOnUse: false,
      );
      cleanupHelper.cleanup.addAll([pValid, pInvalid]);

      final validAuth = PowerAuthAuthentication.password(pValid);
      final invalidAuth = PowerAuthAuthentication.password(pInvalid);
      final body = utf8Bytes('{}');

      var header = await sdk.authenticationHeaderForRequestWithBody(
        validAuth,
        'POST',
        '/some/uriId',
        body,
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
      header = await sdk.authenticationHeaderForRequestWithBody(
        validAuth,
        'POST',
        '/some/uriId',
        body,
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

      header = await sdk.authenticationHeaderForRequestWithBody(
        invalidAuth,
        'POST',
        '/some/uriId',
        body,
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
      header = await sdk.authenticationHeaderForRequestWithBody(
        invalidAuth,
        'POST',
        '/some/uriId',
        body,
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
      cleanupHelper.cleanup.addAll([pValid, pInvalid]);

      final validAuth = PowerAuthAuthentication.password(pValid);
      final invalidAuth = PowerAuthAuthentication.password(pInvalid);
      final body = utf8Bytes('{}');

      var header = await sdk.authenticationHeaderForRequestWithBody(
        validAuth,
        'POST',
        '/some/uriId',
        body,
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
      await expectLater(
        sdk.authenticationHeaderForRequestWithBody(
          validAuth,
          'POST',
          '/some/uriId',
          body,
        ),
        throwsPowerAuthCode(PowerAuthErrorCode.invalidNativeObject),
      );

      header = await sdk.authenticationHeaderForRequestWithBody(
        invalidAuth,
        'POST',
        '/some/uriId',
        body,
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
      await expectLater(
        sdk.authenticationHeaderForRequestWithBody(
          invalidAuth,
          'POST',
          '/some/uriId',
          body,
        ),
        throwsPowerAuthCode(PowerAuthErrorCode.invalidNativeObject),
      );
    });
  });
}
