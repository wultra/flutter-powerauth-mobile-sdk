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

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import '../utils/native_test.dart';

import '../utils/activation_credentials.dart';
import '../utils/helper_functions.dart';
import '../utils/integration_helper.dart';
import '../utils/object_cleanup_helper.dart';

void main() {
  group('Encryptor tests', () {
    late IntegrationHelper helper;
    late ObjectCleanupHelper cleanupHelper;
    late PowerAuth sdk;
    late ActivationCredentials credentials;

    setUp(() async {
      cleanupHelper = ObjectCleanupHelper();
      sdk = PowerAuth(IntegrationHelper.randomString(30));
      helper = IntegrationHelper(sdk);
      await helper.configure();
      credentials = ActivationCredentials();
    });

    tearDown(() async {
      await helper.cleanup();
      await cleanupHelper.dispose();
    });

    test('application scope is available without activation', () async {
      expect(await sdk.hasValidActivation(), isFalse);
      await expectLater(
        sdk.getEncryptorForActivationScope(),
        throwsPowerAuthCode(PowerAuthErrorCode.missingActivation),
      );

      final encryptor = await sdk.getEncryptorForApplicationScope();
      cleanupHelper.cleanup.add(encryptor);
      expect(encryptor.scope, PowerAuthEncryptorScope.application);
      expect(await encryptor.canEncryptRequest(), isTrue);
      expect(await encryptor.canDecryptResponse(), isFalse);

      final encrypted = await encryptor.encryptRequest(utf8Bytes('{}'));
      expect(encrypted.requestBody, isNotEmpty);
      expect(encrypted.requestHeaders, isNotEmpty);
      expect(await encryptor.canEncryptRequest(), isFalse);
      expect(await encryptor.canDecryptResponse(), isTrue);
    });

    test('activation exchange uses one fresh stateful encryptor', () async {
      final userId = IntegrationHelper.randomString(20);
      final expectedUserInfo = helper.userInfo(userId);
      final storeResult = await helper.fillUserInfo(expectedUserInfo);
      expect(storeResult['status'], 'OK');

      await helper.prepareActiveActivation(
        await credentials.validPasswordObject(),
        userId: userId,
      );

      for (var exchange = 0; exchange < 2; exchange++) {
        final encryptor = await sdk.getEncryptorForActivationScope();
        cleanupHelper.cleanup.add(encryptor);
        try {
          expect(encryptor.scope, PowerAuthEncryptorScope.activation);
          expect(await encryptor.canEncryptRequest(), isTrue);
          expect(await encryptor.canDecryptResponse(), isFalse);

          final encrypted = await encryptor.encryptRequest(utf8Bytes('{}'));
          expect(encrypted.requestBody, isNotEmpty);
          expect(encrypted.requestHeaders, isNotEmpty);
          expect(await encryptor.canEncryptRequest(), isFalse);
          expect(await encryptor.canDecryptResponse(), isTrue);

          final response = await helper.callRawSDKEndpoint(
            'user/info',
            body: encrypted.requestBody,
            headers: encrypted.requestHeaders,
          );

          final decrypted = await encryptor.decryptResponse(response.bodyBytes);
          expect(decrypted, isNotEmpty);
          final responseObject =
              jsonDecode(utf8.decode(decrypted)) as Map<String, dynamic>;
          expect(responseObject['sub'], expectedUserInfo.subject);
          await expectLater(
            encryptor.canEncryptRequest(),
            throwsPowerAuthCode(PowerAuthErrorCode.invalidNativeObject),
          );
          await expectLater(
            encryptor.canDecryptResponse(),
            throwsPowerAuthCode(PowerAuthErrorCode.invalidNativeObject),
          );
        } finally {
          await encryptor.release();
        }
      }
    });

    test('release is idempotent and rejects further use', () async {
      await helper.prepareActiveActivation(
        await credentials.validPasswordObject(),
      );
      final encryptor = await sdk.getEncryptorForActivationScope();
      cleanupHelper.cleanup.add(encryptor);

      await encryptor.release();
      await encryptor.release();
      await expectLater(
        encryptor.canEncryptRequest(),
        throwsPowerAuthCode(PowerAuthErrorCode.invalidNativeObject),
      );
      await expectLater(
        encryptor.encryptRequest(utf8Bytes('{}')),
        throwsPowerAuthCode(PowerAuthErrorCode.invalidNativeObject),
      );
    });

    test('owner deconfiguration invalidates an acquired encryptor', () async {
      await helper.prepareActiveActivation(
        await credentials.validPasswordObject(),
      );
      final encryptor = await sdk.getEncryptorForActivationScope();
      cleanupHelper.cleanup.add(encryptor);
      expect(await encryptor.canEncryptRequest(), isTrue);

      await sdk.deconfigure();
      await helper.removeRegistration();
      await expectLater(
        encryptor.canEncryptRequest(),
        throwsPowerAuthCode(PowerAuthErrorCode.invalidNativeObject),
      );
    });
  });
}
