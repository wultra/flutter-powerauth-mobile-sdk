/*
 * Copyright 2026 Wultra s.r.o.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:typed_data';

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/src/powerauth/powerauth_platform_interface.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/src/powerauth_native_object_register/powerauth_native_object_register_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

class _VaultPlatform extends PowerAuthPlatform {
  String? fetchedInstanceId;
  PowerAuthAuthentication? fetchedAuthentication;
  String? fetchedKeyIdentifier;
  final deriveCalls = <(String, int, int)>[];

  @override
  Future<String> fetchSecureVaultKey(
    String instanceId,
    PowerAuthAuthentication authentication,
    String keyIdentifier,
  ) async {
    fetchedInstanceId = instanceId;
    fetchedAuthentication = authentication;
    fetchedKeyIdentifier = keyIdentifier;
    return 'vault-object';
  }

  @override
  Future<Uint8List> deriveSecureVaultKey(
    String objectId,
    int index,
    int keySize,
  ) async {
    deriveCalls.add((objectId, index, keySize));
    return Uint8List.fromList(List<int>.generate(keySize, (i) => index + i));
  }
}

class _RegisterPlatform extends NativeObjectRegisterPlatform {
  final releasedObjectIds = <String>[];

  @override
  Future<void> releaseNativeObject(String objectId) async {
    releasedObjectIds.add(objectId);
  }
}

void main() {
  late PowerAuthPlatform originalPlatform;
  late NativeObjectRegisterPlatform originalRegisterPlatform;
  late _VaultPlatform platform;
  late _RegisterPlatform registerPlatform;

  setUp(() {
    originalPlatform = PowerAuthPlatform.instance;
    originalRegisterPlatform = NativeObjectRegisterPlatform.instance;
    platform = _VaultPlatform();
    registerPlatform = _RegisterPlatform();
    PowerAuthPlatform.instance = platform;
    NativeObjectRegisterPlatform.instance = registerPlatform;
  });

  tearDown(() {
    PowerAuthPlatform.instance = originalPlatform;
    NativeObjectRegisterPlatform.instance = originalRegisterPlatform;
  });

  test('forwards key identity, derives exact bytes, and enforces release', () async {
    final sdk = PowerAuth('vault-instance');
    final authentication = PowerAuthAuthentication.possession();
    final vault = await sdk.fetchSecureVaultKey(
      authentication,
      PowerAuthSecureVaultKeyId.knowledgeOrBiometry,
    );

    expect(vault.keyIdentifier, PowerAuthSecureVaultKeyId.knowledgeOrBiometry);
    expect(platform.fetchedInstanceId, 'vault-instance');
    expect(platform.fetchedAuthentication, same(authentication));
    expect(platform.fetchedKeyIdentifier, 'knowledgeOrBiometry');

    expect(await vault.deriveKey(7, 16), List<int>.generate(16, (i) => 7 + i));
    expect(platform.deriveCalls, [('vault-object', 7, 16)]);

    await expectLater(
      vault.deriveKey(-1, 16),
      throwsA(
        isA<PowerAuthException>().having(
          (error) => error.code,
          'code',
          PowerAuthErrorCode.wrongParameter,
        ),
      ),
    );
    await expectLater(
      vault.deriveKey(0, 15),
      throwsA(
        isA<PowerAuthException>().having(
          (error) => error.code,
          'code',
          PowerAuthErrorCode.wrongParameter,
        ),
      ),
    );
    expect(platform.deriveCalls, [('vault-object', 7, 16)]);

    await vault.release();
    await vault.release();
    expect(registerPlatform.releasedObjectIds, ['vault-object']);
    await expectLater(
      vault.deriveKey(8, 32),
      throwsA(
        isA<PowerAuthException>().having(
          (error) => error.code,
          'code',
          PowerAuthErrorCode.invalidNativeObject,
        ),
      ),
    );
    expect(platform.deriveCalls, [('vault-object', 7, 16)]);
  });
}
