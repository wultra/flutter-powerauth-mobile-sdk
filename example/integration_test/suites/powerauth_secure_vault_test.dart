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

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';

import '../utils/activation_credentials.dart';
import '../utils/helper_functions.dart';
import '../utils/integration_helper.dart';
import '../utils/native_test.dart';
import '../utils/object_cleanup_helper.dart';

void main() {
  group('Secure Vault tests', () {
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
      final password = await credentials.validPasswordObject(destroyOnUse: false);
      cleanupHelper.cleanup.add(password);
      await helper.prepareActiveActivation(password);
    });

    tearDown(() async {
      await helper.cleanup();
      await cleanupHelper.dispose();
    });

    test('derives deterministic isolated keys and enforces lifecycle', () async {
      expect(await sdk.currentAlgorithm, isNot(PowerAuthAlgorithm.legacy));
      final password = await credentials.validPasswordObject(destroyOnUse: false);
      cleanupHelper.cleanup.add(password);
      final authentication = PowerAuthAuthentication.password(password);

      for (final keyIdentifier in PowerAuthSecureVaultKeyId.values) {
        final vault = await sdk.fetchSecureVaultKey(
          authentication,
          keyIdentifier,
        );
        cleanupHelper.cleanup.add(vault);
        expect(vault.keyIdentifier, keyIdentifier);

        final first = await vault.deriveKey(7, 16);
        final repeated = await vault.deriveKey(7, 16);
        final different = await vault.deriveKey(8, 16);
        final extended = await vault.deriveKey(7, 32);
        expect(first, hasLength(16));
        expect(repeated, first);
        expect(different, isNot(first));
        expect(extended, hasLength(32));
        expect(extended.sublist(0, 16), isNot(first));

        await expectLater(
          vault.deriveKey(-1, 16),
          throwsPowerAuthCode(PowerAuthErrorCode.wrongParameter),
        );
        await expectLater(
          vault.deriveKey(0, 15),
          throwsPowerAuthCode(PowerAuthErrorCode.wrongParameter),
        );

        await vault.release();
        await vault.release();
        await expectLater(
          vault.deriveKey(7, 16),
          throwsPowerAuthCode(PowerAuthErrorCode.invalidNativeObject),
        );

        final refetchedVault = await sdk.fetchSecureVaultKey(
          authentication,
          keyIdentifier,
        );
        cleanupHelper.cleanup.add(refetchedVault);
        expect(refetchedVault.keyIdentifier, keyIdentifier);
        expect(await refetchedVault.deriveKey(7, 16), first);

        await refetchedVault.release();
        await expectLater(
          refetchedVault.deriveKey(7, 16),
          throwsPowerAuthCode(PowerAuthErrorCode.invalidNativeObject),
        );
      }
    });
  });
}
