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
  });

  group('PowerAuthBiometryConfiguration', () {
    test('default values', () {
      final defaultLinkItems = Platform.isAndroid;
      final cfg = PowerAuthBiometryConfiguration();

      expect(cfg.authenticateOnBiometricKeySetup, isTrue);
      expect(cfg.linkItemsToCurrentSet, defaultLinkItems);
      expect(cfg.confirmBiometricAuthentication, isFalse);
      expect(cfg.fallbackToDevicePasscode, isFalse);
    });

    test('partial construction', () {
      final defaultLinkItems = Platform.isAndroid;
      final base = PowerAuthBiometryConfiguration();

      final c1 = PowerAuthBiometryConfiguration(
        authenticateOnBiometricKeySetup: false,
      );
      expect(c1.authenticateOnBiometricKeySetup, isFalse);
      expect(c1.linkItemsToCurrentSet, base.linkItemsToCurrentSet);
      expect(
        c1.confirmBiometricAuthentication,
        base.confirmBiometricAuthentication,
      );
      expect(c1.fallbackToDevicePasscode, base.fallbackToDevicePasscode);

      final c2 = PowerAuthBiometryConfiguration(
        linkItemsToCurrentSet: !defaultLinkItems,
      );
      expect(
        c2.authenticateOnBiometricKeySetup,
        base.authenticateOnBiometricKeySetup,
      );
      expect(c2.linkItemsToCurrentSet, !defaultLinkItems);
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
      expect(c3.linkItemsToCurrentSet, base.linkItemsToCurrentSet);
      expect(c3.confirmBiometricAuthentication, isTrue);
      expect(c3.fallbackToDevicePasscode, base.fallbackToDevicePasscode);

      final c4 = PowerAuthBiometryConfiguration(fallbackToDevicePasscode: true);
      expect(
        c4.authenticateOnBiometricKeySetup,
        base.authenticateOnBiometricKeySetup,
      );
      expect(c4.linkItemsToCurrentSet, base.linkItemsToCurrentSet);
      expect(
        c4.confirmBiometricAuthentication,
        base.confirmBiometricAuthentication,
      );
      expect(c4.fallbackToDevicePasscode, isTrue);
    });
  });

  group('PowerAuthKeychainConfiguration', () {
    test('default values', () {
      final cfg = PowerAuthKeychainConfiguration();
      expect(
        cfg.minimalRequiredKeychainProtection,
        PowerAuthKeychainProtection.none,
      );
      expect(cfg.accessGroupName, isNull);
      expect(cfg.userDefaultsSuiteName, isNull);
    });

    test('partial construction', () {
      final base = PowerAuthKeychainConfiguration();

      final c1 = PowerAuthKeychainConfiguration(
        minimalRequiredKeychainProtection:
            PowerAuthKeychainProtection.strongbox,
      );
      expect(
        c1.minimalRequiredKeychainProtection,
        PowerAuthKeychainProtection.strongbox,
      );

      final c2 = PowerAuthKeychainConfiguration(
        accessGroupName: 'test.accessGroup',
      );
      expect(c2.accessGroupName, 'test.accessGroup');
      expect(
        c2.minimalRequiredKeychainProtection,
        base.minimalRequiredKeychainProtection,
      );
      expect(c2.userDefaultsSuiteName, isNull);

      final c3 = PowerAuthKeychainConfiguration(
        userDefaultsSuiteName: 'SuperDefaults',
      );
      expect(c3.userDefaultsSuiteName, 'SuperDefaults');
      expect(
        c3.minimalRequiredKeychainProtection,
        base.minimalRequiredKeychainProtection,
      );
    });
  });
}
