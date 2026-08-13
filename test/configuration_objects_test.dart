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

import 'dart:io';

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PowerAuthConfiguration', () {
    test('default values', () {
      final cfg = PowerAuthConfiguration(
        configuration: 'configuration',
        baseEndpointUrl: 'https://example.com',
      );
      expect(cfg.algorithm, isNull);
      expect(
        cfg.offlineAuthenticationCodeComponentLength,
        PowerAuthConfiguration.defaultOfflineAuthenticationCodeComponentLength,
      );
    });

    test('serialization', () {
      final cfg = PowerAuthConfiguration(
        configuration: 'configuration',
        baseEndpointUrl: 'https://example.com',
        algorithm: PowerAuthAlgorithm.p384l3,
        offlineAuthenticationCodeComponentLength: 6,
      );
      final restored = PowerAuthConfiguration.fromMap(cfg.toMap());
      expect(restored.configuration, cfg.configuration);
      expect(restored.baseEndpointUrl, cfg.baseEndpointUrl);
      expect(restored.algorithm, cfg.algorithm);
      expect(
        restored.offlineAuthenticationCodeComponentLength,
        cfg.offlineAuthenticationCodeComponentLength,
      );
    });
  });

  group('PowerAuthSharingConfiguration', () {
    test('serialization', () {
      final cfg = PowerAuthSharingConfiguration(
        appGroup: 'group.com.wultra.test',
        appIdentifier: 'com.wultra.test',
        keychainAccessGroup: 'com.wultra.test.keychain',
        sharedMemoryIdentifier: 'test',
      );

      final restored = PowerAuthSharingConfiguration.fromMap(cfg.toMap());

      expect(restored.appGroup, cfg.appGroup);
      expect(restored.appIdentifier, cfg.appIdentifier);
      expect(restored.keychainAccessGroup, cfg.keychainAccessGroup);
      expect(restored.sharedMemoryIdentifier, cfg.sharedMemoryIdentifier);
    });

    test('shared memory identifier is optional', () {
      final cfg = PowerAuthSharingConfiguration(
        appGroup: 'group.com.wultra.test',
        appIdentifier: 'com.wultra.test',
        keychainAccessGroup: 'com.wultra.test.keychain',
      );

      expect(cfg.sharedMemoryIdentifier, isNull);
      expect(
        PowerAuthSharingConfiguration.fromMap(
          cfg.toMap(),
        ).sharedMemoryIdentifier,
        isNull,
      );
    });
  });

  group('PowerAuthClientConfiguration', () {
    test('default values', () {
      const defaultTimeout = 20;

      final cfg = PowerAuthClientConfiguration();
      expect(cfg.connectionTimeout, defaultTimeout);
      expect(cfg.readTimeout, defaultTimeout);
      expect(cfg.enableUnsecureTraffic, isFalse);
      expect(cfg.customHttpHeaders, isNull);
      expect(cfg.basicHttpAuthentication, isNull);
    });

    test('partial construction', () {
      final defaultCfg = PowerAuthClientConfiguration();

      final changed1 = PowerAuthClientConfiguration(connectionTimeout: 5);
      expect(changed1.connectionTimeout, 5);
      expect(changed1.readTimeout, defaultCfg.readTimeout);
      expect(changed1.enableUnsecureTraffic, defaultCfg.enableUnsecureTraffic);

      final changed2 = PowerAuthClientConfiguration(readTimeout: 5);
      expect(changed2.connectionTimeout, defaultCfg.connectionTimeout);
      expect(changed2.readTimeout, 5);
      expect(changed2.enableUnsecureTraffic, defaultCfg.enableUnsecureTraffic);

      final changed3 = PowerAuthClientConfiguration(
        enableUnsecureTraffic: true,
      );
      expect(changed3.connectionTimeout, defaultCfg.connectionTimeout);
      expect(changed3.readTimeout, defaultCfg.readTimeout);
      expect(changed3.enableUnsecureTraffic, isTrue);
    });

    test('serialization', () {
      final cfg = PowerAuthClientConfiguration(
        connectionTimeout: 5,
        readTimeout: 7,
        enableUnsecureTraffic: true,
      );
      final restored = PowerAuthClientConfiguration.fromMap(cfg.toMap());

      expect(restored.connectionTimeout, cfg.connectionTimeout);
      expect(restored.readTimeout, cfg.readTimeout);
      expect(restored.enableUnsecureTraffic, cfg.enableUnsecureTraffic);
    });
  });

  group('PowerAuthBiometryConfiguration', () {
    test('default values', () {
      final defaultInvalidateAfterChange = Platform.isAndroid;
      final cfg = PowerAuthBiometryConfiguration();

      expect(cfg.authenticateOnBiometricKeySetup, isTrue);
      expect(
        cfg.invalidateBiometricFactorAfterChange,
        defaultInvalidateAfterChange,
      );
      expect(cfg.confirmBiometricAuthentication, isFalse);
      expect(cfg.fallbackToDevicePasscode, isFalse);
      expect(cfg.fallbackToSharedBiometryKey, isTrue);
      expect(cfg.useLegacySymmetricKey, isFalse);
    });

    test('partial construction', () {
      final defaultInvalidateAfterChange = Platform.isAndroid;
      final base = PowerAuthBiometryConfiguration();

      final c1 = PowerAuthBiometryConfiguration(
        authenticateOnBiometricKeySetup: false,
      );
      expect(c1.authenticateOnBiometricKeySetup, isFalse);
      expect(
        c1.invalidateBiometricFactorAfterChange,
        base.invalidateBiometricFactorAfterChange,
      );
      expect(
        c1.confirmBiometricAuthentication,
        base.confirmBiometricAuthentication,
      );
      expect(c1.fallbackToDevicePasscode, base.fallbackToDevicePasscode);

      final c2 = PowerAuthBiometryConfiguration(
        invalidateBiometricFactorAfterChange: !defaultInvalidateAfterChange,
      );
      expect(
        c2.authenticateOnBiometricKeySetup,
        base.authenticateOnBiometricKeySetup,
      );
      expect(
        c2.invalidateBiometricFactorAfterChange,
        !defaultInvalidateAfterChange,
      );
      expect(
        c2.confirmBiometricAuthentication,
        base.confirmBiometricAuthentication,
      );
      expect(c2.fallbackToDevicePasscode, base.fallbackToDevicePasscode);

      final c3 = PowerAuthBiometryConfiguration(
        confirmBiometricAuthentication: true,
      );
      expect(
        c3.authenticateOnBiometricKeySetup,
        base.authenticateOnBiometricKeySetup,
      );
      expect(
        c3.invalidateBiometricFactorAfterChange,
        base.invalidateBiometricFactorAfterChange,
      );
      expect(c3.confirmBiometricAuthentication, isTrue);
      expect(c3.fallbackToDevicePasscode, base.fallbackToDevicePasscode);

      final c4 = PowerAuthBiometryConfiguration(fallbackToDevicePasscode: true);
      expect(
        c4.authenticateOnBiometricKeySetup,
        base.authenticateOnBiometricKeySetup,
      );
      expect(
        c4.invalidateBiometricFactorAfterChange,
        base.invalidateBiometricFactorAfterChange,
      );
      expect(
        c4.confirmBiometricAuthentication,
        base.confirmBiometricAuthentication,
      );
      expect(c4.fallbackToDevicePasscode, isTrue);

      final c5 = PowerAuthBiometryConfiguration(useLegacySymmetricKey: true);
      expect(c5.useLegacySymmetricKey, isTrue);
      expect(
        c5.authenticateOnBiometricKeySetup,
        base.authenticateOnBiometricKeySetup,
      );

      final c6 = PowerAuthBiometryConfiguration(
        fallbackToSharedBiometryKey: false,
      );
      expect(c6.fallbackToSharedBiometryKey, isFalse);
    });

    test('serialization', () {
      final cfg = PowerAuthBiometryConfiguration(
        invalidateBiometricFactorAfterChange: false,
        fallbackToDevicePasscode: true,
        confirmBiometricAuthentication: true,
        authenticateOnBiometricKeySetup: false,
        fallbackToSharedBiometryKey: false,
        useLegacySymmetricKey: true,
      );
      final restored = PowerAuthBiometryConfiguration.fromMap(cfg.toMap());

      expect(
        restored.invalidateBiometricFactorAfterChange,
        cfg.invalidateBiometricFactorAfterChange,
      );
      expect(restored.fallbackToDevicePasscode, cfg.fallbackToDevicePasscode);
      expect(
        restored.confirmBiometricAuthentication,
        cfg.confirmBiometricAuthentication,
      );
      expect(
        restored.authenticateOnBiometricKeySetup,
        cfg.authenticateOnBiometricKeySetup,
      );
      expect(
        restored.fallbackToSharedBiometryKey,
        cfg.fallbackToSharedBiometryKey,
      );
      expect(restored.useLegacySymmetricKey, cfg.useLegacySymmetricKey);
    });
  });

  group('PowerAuthKeychainConfiguration', () {
    test('default values', () {
      final cfg = PowerAuthKeychainConfiguration();
      expect(
        cfg.minimalRequiredKeychainProtection,
        PowerAuthKeychainProtection.none,
      );
    });

    test('explicit value and serialization', () {
      final cfg = PowerAuthKeychainConfiguration(
        minimalRequiredKeychainProtection:
            PowerAuthKeychainProtection.strongbox,
      );
      final restored = PowerAuthKeychainConfiguration.fromMap(cfg.toMap());

      expect(
        restored.minimalRequiredKeychainProtection,
        PowerAuthKeychainProtection.strongbox,
      );
    });
  });

  group('PowerAuthSharingConfiguration', () {
    test('explicit values and serialization', () {
      final cfg = PowerAuthSharingConfiguration(
        appGroup: 'group.com.example.app',
        appIdentifier: 'com.example.app',
        keychainAccessGroup: 'TEAMID.com.example.shared',
      );
      final restored = PowerAuthSharingConfiguration.fromMap(cfg.toMap());

      expect(restored.appGroup, cfg.appGroup);
      expect(restored.appIdentifier, cfg.appIdentifier);
      expect(restored.keychainAccessGroup, cfg.keychainAccessGroup);
      expect(restored.toMap(), cfg.toMap());
    });
  });
}
