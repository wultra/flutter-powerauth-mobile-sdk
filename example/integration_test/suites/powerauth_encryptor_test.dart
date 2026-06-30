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
import '../utils/activation_credentials.dart';
import '../utils/integration_helper.dart';

import 'package:flutter_test/flutter_test.dart';

main() {
  group('Encryptor tests', () {
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

    test('testEncryptorWithoutActivation', () async {
      expect(await sdk.hasValidActivation(), false);
      final activationScoped = sdk.getEncryptorForActivationScope();
      expect(await activationScoped.canEncryptRequest(), false);

      final applicationScoped = sdk.getEncryptorForApplicationScope();
      expect(await applicationScoped.canEncryptRequest(), true);

      expect(
        activationScoped.encryptRequest("{}"),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.missingActivation,
          ),
        ),
      );
      expect(await applicationScoped.encryptRequest("{}"), isNotNull);
    });

    test('testActivationScopedEncryptionDefault', () async {
      await helper.prepareActiveActivation(
        await credentials.validPasswordObject(),
      );
      final encryptor = sdk.getEncryptorForActivationScope();
      expect(encryptor.encryptorScope, PowerAuthEncryptorScope.activation);

      for (var i = 1; i <= 2; i++) {
        // Encrypt request
        expect(await encryptor.canEncryptRequest(), true);
        final requestData = '{}';
        final encrypted = await encryptor.encryptRequest(requestData);
        final decryptor = encrypted.decryptor;
        expect(encrypted.cryptogram, isNotNull);
        expect(encrypted.header, isNotNull);
        expect(decryptor, isNotNull);
        expect(decryptor.decryptorScope, encryptor.encryptorScope);
        expect(await decryptor.canDecryptResponse(), true);

        // Let's use "user info" service for the test.
        final headers = {encrypted.header.name: encrypted.header.value};
        final response = await helper.callSDKEndpoint(
          '/pa/v3/user/info',
          jsonEncode(encrypted.cryptogram.toMap()),
          headers,
        );
        expect(await decryptor.canDecryptResponse(), true);

        // Decrypt response
        final decrypted = await decryptor.decryptResponse(
          PowerAuthCryptogram.fromMap(response),
        );
        expect(decrypted, isNotNull);
        final decryptedObject = jsonDecode(decrypted);

        // Response contains 'sub' key which should be equal to user-id
        expect(decryptedObject["sub"], helper.userId);
        expect(await decryptor.canDecryptResponse(), false);
      }
    });

    test('testActivationScopedEncryptionStringFormat', () async {
      await helper.prepareActiveActivation(
        await credentials.validPasswordObject(),
      );

      // Acquire encryptor
      final encryptor = sdk.getEncryptorForActivationScope();
      expect(encryptor.encryptorScope, PowerAuthEncryptorScope.activation);

      for (var i = 1; i <= 2; i++) {
        // Encrypt request
        expect(await encryptor.canEncryptRequest(), true);
        final requestData = '{}';
        final encrypted = await encryptor.encryptRequest(
          requestData,
          PowerAuthDataFormat.utf8,
        );
        final decryptor = encrypted.decryptor;
        expect(encrypted.cryptogram, isNotNull);
        expect(encrypted.header, isNotNull);
        expect(decryptor, isNotNull);
        expect(decryptor.decryptorScope, encryptor.encryptorScope);
        expect(await decryptor.canDecryptResponse(), true);

        // Let's use "user info" service for the test.
        final headers = {encrypted.header.name: encrypted.header.value};
        final response = await helper.callSDKEndpoint(
          '/pa/v3/user/info',
          jsonEncode(encrypted.cryptogram.toMap()),
          headers,
        );
        expect(await decryptor.canDecryptResponse(), true);

        // Decrypt response
        final decrypted = await decryptor.decryptResponse(
          PowerAuthCryptogram.fromMap(response),
          PowerAuthDataFormat.utf8,
        );
        expect(decrypted, isNotNull);
        final decryptedObject = jsonDecode(decrypted);

        // Response contains 'sub' key which should be equal to user-id
        expect(decryptedObject['sub'], helper.userId);
        expect(await decryptor.canDecryptResponse(), false);
      }
    });

    test('testActivationScopedEncryptionBase64Format', () async {
      await helper.prepareActiveActivation(
        await credentials.validPasswordObject(),
      );

      // Acquire encryptor
      final encryptor = sdk.getEncryptorForActivationScope();
      expect(encryptor.encryptorScope, PowerAuthEncryptorScope.activation);

      for (var i = 1; i <= 2; i++) {
        // Encrypt request
        expect(await encryptor.canEncryptRequest(), true);
        final data = base64.encode(utf8.encode("{}"));
        final encrypted = await encryptor.encryptRequest(
          data,
          PowerAuthDataFormat.base64,
        );
        final decryptor = encrypted.decryptor;
        expect(encrypted.cryptogram, isNotNull);
        expect(encrypted.header, isNotNull);
        expect(decryptor, isNotNull);
        expect(decryptor.decryptorScope, encryptor.encryptorScope);
        expect(await decryptor.canDecryptResponse(), true);

        // Let's use "user info" service for the test.
        final headers = {encrypted.header.name: encrypted.header.value};
        final response = await helper.callSDKEndpoint(
          '/pa/v3/user/info',
          jsonEncode(encrypted.cryptogram.toMap()),
          headers,
        );
        expect(await decryptor.canDecryptResponse(), true);

        // Decrypt response
        final decrypted = await decryptor.decryptResponse(
          PowerAuthCryptogram.fromMap(response),
          PowerAuthDataFormat.base64,
        );
        expect(decrypted, isNotNull);

        // Response contains 'sub' key which should be equal to user-id
        final decryptedObject = jsonDecode(
          utf8.decode(base64Decode(decrypted)),
        );
        expect(decryptedObject['sub'], helper.userId);

        expect(await decryptor.canDecryptResponse(), false);
      }
    });

    test('testReleaseEncryptorAndDecryptor', () async {
      await helper.prepareActiveActivation(
        await credentials.validPasswordObject(),
      );

      // Acquire encryptor
      final encryptor = sdk.getEncryptorForActivationScope();
      expect(encryptor.encryptorScope, PowerAuthEncryptorScope.activation);
      expect(await encryptor.canEncryptRequest(), true);

      final data = base64.encode(utf8.encode("{}"));
      final encrypted = await encryptor.encryptRequest(
        data,
        PowerAuthDataFormat.base64,
      );
      final decryptor = encrypted.decryptor;
      expect(encrypted.cryptogram, isNotNull);
      expect(encrypted.header, isNotNull);
      expect(decryptor, isNotNull);
      expect(await decryptor.canDecryptResponse(), true);

      await decryptor.release();
      expect(await decryptor.canDecryptResponse(), false);

      expect(await encryptor.canEncryptRequest(), true);

      // Remove activation also deactivate the encryptor
      await sdk.removeActivationWithAuthentication(
        await credentials.knowledge(),
      );
      expect(await encryptor.canEncryptRequest(), false);
    });

    test('testEncryptorAfterActivationRemove', () async {
      await helper.prepareActiveActivation(
        await credentials.validPasswordObject(),
      );
      final encryptor = sdk.getEncryptorForActivationScope();
      expect(encryptor.encryptorScope, PowerAuthEncryptorScope.activation);
      expect(await encryptor.canEncryptRequest(), true);

      final data = base64.encode(utf8.encode("{}"));
      final encrypted = await encryptor.encryptRequest(
        data,
        PowerAuthDataFormat.base64,
      );
      final decryptor = encrypted.decryptor;
      expect(encrypted.cryptogram, isNotNull);
      expect(encrypted.header, isNotNull);
      expect(decryptor, isNotNull);
      expect(await decryptor.canDecryptResponse(), true);

      await sdk.removeActivationLocal();
      expect(await encryptor.canEncryptRequest(), false);
      expect(await decryptor.canDecryptResponse(), false);
    });

    test('testEncryptorAfterDeconfigure', () async {
      await helper.prepareActiveActivation(
        await credentials.validPasswordObject(),
      );

      // Acquire encryptor
      final encryptor = sdk.getEncryptorForActivationScope();
      expect(encryptor.encryptorScope, PowerAuthEncryptorScope.activation);
      expect(await encryptor.canEncryptRequest(), true);

      // Encrypt request
      final data = base64.encode(utf8.encode("{}"));
      final encrypted = await encryptor.encryptRequest(
        data,
        PowerAuthDataFormat.base64,
      );

      // Decrypt response
      final decryptor = encrypted.decryptor;
      expect(encrypted.cryptogram, isNotNull);
      expect(encrypted.header, isNotNull);
      expect(decryptor, isNotNull);
      expect(await decryptor.canDecryptResponse(), true);

      // Deconfigure
      final configuration = await sdk.configuration;
      expect(configuration, isNotNull);

      await sdk.deconfigure();
      expect(await encryptor.canEncryptRequest(), false);
      expect(await decryptor.canDecryptResponse(), false);

      // Reconfigure
      await sdk.configure(configuration: configuration);
      expect(await encryptor.canEncryptRequest(), false);
      expect(await decryptor.canDecryptResponse(), false);
    });
  });
}
