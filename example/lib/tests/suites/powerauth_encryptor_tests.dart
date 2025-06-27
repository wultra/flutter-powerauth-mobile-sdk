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
import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/suites/test_suite.dart';

class PowerAuthEncryptorTests extends TestSuiteWithActivation {

  @override
  List<Future<void> Function()> getTests() => [
    testEncryptorWithoutActivation,
    testActivationScopedEncryptionDefault,
    testActivationScopedEncryptionStringFormat,
    testActivationScopedEncryptionBase64Format,
    testReleaseEncryptorAndDecryptor,
    testEncryptorAfterActivationRemove,
    testEncryptorAfterDeconfigure
  ];

  Future<void> testEncryptorWithoutActivation() async {
    await expect(sdk.hasValidActivation()).toBe(false);
    final activationScoped = sdk.getEncryptorForActivationScope();
    await expect(activationScoped.canEncryptRequest()).toBe(false);

    final applicationScoped = sdk.getEncryptorForApplicationScope();
    await expect(applicationScoped.canEncryptRequest()).toBe(true);

    await expect(activationScoped.encryptRequest("{}")).toThrow(PowerAuthErrorCode.missingActivation);
    await expect(applicationScoped.encryptRequest("{}")).toBeDefined();
  }

  Future<void> testActivationScopedEncryptionDefault() async {

    await helper.prepareActiveActivation(await credentials.validPasswordObject());

    // Acquire encryptor
    final encryptor = sdk.getEncryptorForActivationScope();
    await expect(encryptor.encryptorScope).toBe(PowerAuthEncryptorScope.activation);

    for (var i = 1; i <= 2; i++) {
      // Encrypt request
      await expect(encryptor.canEncryptRequest()).toBe(true);
      final requestData = '{}';
      final encrypted = await encryptor.encryptRequest(requestData);
      final decryptor = encrypted.decryptor;
      await expect(encrypted.cryptogram).toBeDefined();
      await expect(encrypted.header).toBeDefined();
      await expect(decryptor).toBeDefined();
      await expect(decryptor.decryptorScope).toBe(encryptor.encryptorScope);
      await expect(decryptor.canDecryptResponse()).toBe(true);

      // Let's use "user info" service for the test.
      final headers = { encrypted.header.name: encrypted.header.value };
      final response = await helper.callSDKEndpoint('/pa/v3/user/info', jsonEncode(encrypted.cryptogram.toMap()), headers);
      await expect(decryptor.canDecryptResponse()).toBe(true);

      // Decrypt response
      final decrypted = await decryptor.decryptResponse(PowerAuthCryptogram.fromMap(response));
      await expect(decrypted).toBeDefined();
      final decryptedObject = jsonDecode(decrypted);

      // Response contains 'sub' key which should be equal to user-id
      await expect(decryptedObject["sub"]).toBe(helper.userId);
      await expect(decryptor.canDecryptResponse()).toBe(false);
    }
  }

  Future<void> testActivationScopedEncryptionStringFormat() async {

    await helper.prepareActiveActivation(await credentials.validPasswordObject());

    // Acquire encryptor
    final encryptor = sdk.getEncryptorForActivationScope();
    await expect(encryptor.encryptorScope).toBe(PowerAuthEncryptorScope.activation);

    for (var i = 1; i <= 2; i++) {
      // Encrypt request
      await expect(encryptor.canEncryptRequest()).toBe(true);
      final requestData = '{}';
      final encrypted = await encryptor.encryptRequest(requestData, PowerAuthDataFormat.utf8);
      final decryptor = encrypted.decryptor;
      await expect(encrypted.cryptogram).toBeDefined();
      await expect(encrypted.header).toBeDefined();
      await expect(decryptor).toBeDefined();
      await expect(decryptor.decryptorScope).toBe(encryptor.encryptorScope);
      await expect(decryptor.canDecryptResponse()).toBe(true);

      // Let's use "user info" service for the test.
      final headers = { encrypted.header.name: encrypted.header.value };
      final response = await helper.callSDKEndpoint('/pa/v3/user/info', jsonEncode(encrypted.cryptogram.toMap()), headers);
      await expect(decryptor.canDecryptResponse()).toBe(true);

      // Decrypt response
      final decrypted = await decryptor.decryptResponse(PowerAuthCryptogram.fromMap(response), PowerAuthDataFormat.utf8);
      await expect(decrypted).toBeDefined();
      final decryptedObject = jsonDecode(decrypted);

      // Response contains 'sub' key which should be equal to user-id
      await expect(decryptedObject['sub']).toBe(helper.userId);
      await expect(decryptor.canDecryptResponse()).toBe(false);
    }
  }

  Future<void> testActivationScopedEncryptionBase64Format() async {

    await helper.prepareActiveActivation(await credentials.validPasswordObject());

    // Acquire encryptor
    final encryptor = sdk.getEncryptorForActivationScope();
    await expect(encryptor.encryptorScope).toBe(PowerAuthEncryptorScope.activation);

    for (var i = 1; i <= 2; i++) {
      // Encrypt request
      await expect(encryptor.canEncryptRequest()).toBe(true);
      final data = base64.encode(utf8.encode("{}"));
      final encrypted = await encryptor.encryptRequest(data, PowerAuthDataFormat.base64);
      final decryptor = encrypted.decryptor;
      await expect(encrypted.cryptogram).toBeDefined();
      await expect(encrypted.header).toBeDefined();
      await expect(decryptor).toBeDefined();
      await expect(decryptor.decryptorScope).toBe(encryptor.encryptorScope);
      await expect(decryptor.canDecryptResponse()).toBe(true);

      // Let's use "user info" service for the test
      final headers = { encrypted.header.name: encrypted.header.value };
      final response = await helper.callSDKEndpoint('/pa/v3/user/info', jsonEncode(encrypted.cryptogram.toMap()), headers);
      await expect(decryptor.canDecryptResponse()).toBe(true);

      // Decrypt response
      final decrypted = await decryptor.decryptResponse(PowerAuthCryptogram.fromMap(response), PowerAuthDataFormat.base64);
      await expect(decrypted).toBeDefined();
      final decryptedObject = jsonDecode(utf8.decode(base64Decode(decrypted)));
      await expect(decryptedObject['sub']).toBe(helper.userId);

      await expect(decryptor.canDecryptResponse()).toBe(false);
    }
  }

  Future<void> testReleaseEncryptorAndDecryptor() async {

    await helper.prepareActiveActivation(await credentials.validPasswordObject());

    // Acquire encryptor
    final encryptor = sdk.getEncryptorForActivationScope();
    await expect(encryptor.encryptorScope).toBe(PowerAuthEncryptorScope.activation);

    // Encrypt request
    await expect(encryptor.canEncryptRequest()).toBe(true);

    final data = base64.encode(utf8.encode("{}"));
    final encrypted = await encryptor.encryptRequest(data, PowerAuthDataFormat.base64);
    final decryptor = encrypted.decryptor;
    await expect(encrypted.cryptogram).toBeDefined();
    await expect(encrypted.header).toBeDefined();
    await expect(decryptor).toBeDefined();
    await expect(decryptor.canDecryptResponse()).toBe(true);

    await decryptor.release();
    await expect(decryptor.canDecryptResponse()).toBe(false);

    await expect(encryptor.canEncryptRequest()).toBe(true);

    // Remove activation also deactivate the encryptor
    await sdk.removeActivationWithAuthentication(await credentials.knowledge());
    await expect(encryptor.canEncryptRequest()).toBe(false);
  }

  Future<void> testEncryptorAfterActivationRemove() async {

    await helper.prepareActiveActivation(await credentials.validPasswordObject());

    // Acquire encryptor
    final encryptor = sdk.getEncryptorForActivationScope();
    await expect(encryptor.encryptorScope).toBe(PowerAuthEncryptorScope.activation);

    // Encrypt request
    await expect(encryptor.canEncryptRequest()).toBe(true);

    final data = base64.encode(utf8.encode("{}"));
    final encrypted = await encryptor.encryptRequest(data, PowerAuthDataFormat.base64);
    final decryptor = encrypted.decryptor;
    await expect(encrypted.cryptogram).toBeDefined();
    await expect(encrypted.header).toBeDefined();
    await expect(decryptor).toBeDefined();
    await expect(decryptor.canDecryptResponse()).toBe(true);

    await sdk.removeActivationLocal();
    await expect(encryptor.canEncryptRequest()).toBe(false);
    await expect(decryptor.canDecryptResponse()).toBe(false);
  }

  Future<void> testEncryptorAfterDeconfigure() async {

    await helper.prepareActiveActivation(await credentials.validPasswordObject());

    // Acquire encryptor
    final encryptor = sdk.getEncryptorForActivationScope();
    await expect(encryptor.encryptorScope).toBe(PowerAuthEncryptorScope.activation);

    // Encrypt request
    await expect(encryptor.canEncryptRequest()).toBe(true);

    final data = base64.encode(utf8.encode("{}"));
    final encrypted = await encryptor.encryptRequest(data, PowerAuthDataFormat.base64);
    final decryptor = encrypted.decryptor;
    await expect(encrypted.cryptogram).toBeDefined();
    await expect(encrypted.header).toBeDefined();
    await expect(decryptor).toBeDefined();
    await expect(decryptor.canDecryptResponse()).toBe(true);

    final configuration = sdk.configuration;
    await expect(configuration).toBeDefined();

    await sdk.deconfigure();
    await expect(encryptor.canEncryptRequest()).toBe(false);
    await expect(decryptor.canDecryptResponse()).toBe(false);
    
    // Reconfigure
    await sdk.configure(configuration: configuration!);
    await expect(encryptor.canEncryptRequest()).toBe(false);
    await expect(decryptor.canDecryptResponse()).toBe(false);
  }
}