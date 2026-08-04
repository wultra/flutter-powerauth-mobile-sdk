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
import '../utils/integration_helper.dart';
import '../utils/native_test.dart';
import '../utils/object_cleanup_helper.dart';

void main() {
  group('Protocol upgrade tests', () {
    late IntegrationHelper helper;
    late ObjectCleanupHelper cleanupHelper;
    late PowerAuth sdk;
    late ActivationCredentials credentials;

    setUp(() async {
      cleanupHelper = ObjectCleanupHelper();
      sdk = PowerAuth(IntegrationHelper.randomString(30));
      helper = IntegrationHelper(sdk);
      credentials = ActivationCredentials();
      await helper.configure();
    });

    tearDown(() async {
      await helper.cleanup();
      await cleanupHelper.dispose();
    });

    test('upgrades a persisted legacy activation to protocol 4', () async {
      final configured = await sdk.configuration;
      await sdk.deconfigure();
      await sdk.configure(
        configuration: PowerAuthConfiguration(
          configuration: configured.configuration,
          baseEndpointUrl: configured.baseEndpointUrl,
          algorithm: PowerAuthAlgorithm.legacy,
          offlineAuthenticationCodeComponentLength:
              configured.offlineAuthenticationCodeComponentLength,
        ),
      );
      final persistencePassword = await credentials.validPasswordObject();
      cleanupHelper.cleanup.add(persistencePassword);
      await helper.prepareActiveActivation(persistencePassword);
      expect(await sdk.currentAlgorithm, PowerAuthAlgorithm.legacy);

      await sdk.deconfigure();
      await sdk.configure(
        configuration: PowerAuthConfiguration(
          configuration: configured.configuration,
          baseEndpointUrl: configured.baseEndpointUrl,
          algorithm: PowerAuthAlgorithm.p384l3,
          offlineAuthenticationCodeComponentLength:
              configured.offlineAuthenticationCodeComponentLength,
        ),
      );
      expect(await sdk.hasValidActivation(), isTrue);
      expect(await sdk.currentAlgorithm, PowerAuthAlgorithm.legacy);

      await sdk.fetchActivationStatus();
      expect(await sdk.hasProtocolUpgradeAvailable(), isTrue);
      expect(await sdk.hasPendingProtocolUpgrade(), isFalse);
      final upgradePassword = await credentials.validPasswordObject();
      cleanupHelper.cleanup.add(upgradePassword);
      final result = await sdk.startProtocolUpgrade(upgradePassword);
      expect(result.biometryFactorRemoved, isFalse);

      if (result.activationStatusFetchRequired) {
        expect(result.activationFingerprint, isNull);
        expect(await sdk.hasPendingProtocolUpgrade(), isTrue);
        await sdk.fetchActivationStatus();
      } else {
        expect(result.activationFingerprint, isNotNull);
      }

      expect(await sdk.hasPendingProtocolUpgrade(), isFalse);
      expect(await sdk.hasProtocolUpgradeAvailable(), isFalse);
      expect(await sdk.currentAlgorithm, PowerAuthAlgorithm.p384l3);
      expect(await sdk.hasValidActivation(), isTrue);
      expect(await sdk.getActivationFingerprint(), isNotNull);
    });
  });
}
