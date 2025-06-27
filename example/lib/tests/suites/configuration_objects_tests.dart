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
import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/suites/test_suite.dart';

class ConfigurationObjectsTests extends TestSuite{

  @override
  List<Future<void> Function()> getTests() {
    return [testClientConfiguration,testBiometryConfiguration,testKeychainConfiguration];
  }

  Future<void> testClientConfiguration() async {
    // Default config
    final defaultConfig = PowerAuthClientConfiguration();
    await expect(defaultConfig.connectionTimeout).toBe(20);
    await expect(defaultConfig.readTimeout).toBe(20);
    await expect(defaultConfig.enableUnsecureTraffic).toBe(false);
    await expect(defaultConfig.customHttpHeaders).toBeNull();
    await expect(defaultConfig.basicHttpAuthentication).toBeNull();

    // Now try to build config from some incomplete objects
    final changed1 = PowerAuthClientConfiguration(connectionTimeout: 5);
    await expect(changed1.connectionTimeout).toBe(5);
    await expect(changed1.readTimeout).toBe(defaultConfig.readTimeout);
    await expect(changed1.enableUnsecureTraffic).toBe(defaultConfig.enableUnsecureTraffic);

    final changed2 = PowerAuthClientConfiguration(readTimeout: 5);
    await expect(changed2.connectionTimeout).toBe(defaultConfig.connectionTimeout);
    await expect(changed2.readTimeout).toBe(5);
    await expect(changed2.enableUnsecureTraffic).toBe(defaultConfig.enableUnsecureTraffic);

    final changed3 = PowerAuthClientConfiguration(enableUnsecureTraffic: true);
    await expect(changed3.connectionTimeout).toBe(defaultConfig.connectionTimeout);
    await expect(changed3.readTimeout).toBe(defaultConfig.readTimeout);
    await expect(changed3.enableUnsecureTraffic).toBe(true);
  }

  Future<void> testBiometryConfiguration() async {
    final defaultLinkItems = Platform.isAndroid;
    // Default config
    final defaultConfig = PowerAuthBiometryConfiguration();
    await expect(defaultConfig.authenticateOnBiometricKeySetup).toBe(true);
    await expect(defaultConfig.linkItemsToCurrentSet).toBe(defaultLinkItems);
    await expect(defaultConfig.confirmBiometricAuthentication).toBe(false);
    await expect(defaultConfig.fallbackToDevicePasscode).toBe(false);

    // Now try to build config from some incomplete objects
    final config1 = PowerAuthBiometryConfiguration(authenticateOnBiometricKeySetup: false);
    await expect(config1.authenticateOnBiometricKeySetup).toBe(false);
    await expect(config1.linkItemsToCurrentSet).toBe(defaultConfig.linkItemsToCurrentSet);
    await expect(config1.confirmBiometricAuthentication).toBe(defaultConfig.confirmBiometricAuthentication);
    await expect(config1.fallbackToDevicePasscode).toBe(defaultConfig.fallbackToDevicePasscode);

    final config2 = PowerAuthBiometryConfiguration(linkItemsToCurrentSet: !defaultLinkItems);
    await expect(config2.authenticateOnBiometricKeySetup).toBe(defaultConfig.authenticateOnBiometricKeySetup);
    await expect(config2.linkItemsToCurrentSet).toBe(!defaultLinkItems);
    await expect(config2.confirmBiometricAuthentication).toBe(defaultConfig.confirmBiometricAuthentication);
    await expect(config2.fallbackToDevicePasscode).toBe(defaultConfig.fallbackToDevicePasscode);

    final config3 = PowerAuthBiometryConfiguration(confirmBiometricAuthentication: true);
    await expect(config3.authenticateOnBiometricKeySetup).toBe(defaultConfig.authenticateOnBiometricKeySetup);
    await expect(config3.linkItemsToCurrentSet).toBe(defaultConfig.linkItemsToCurrentSet);
    await expect(config3.confirmBiometricAuthentication).toBe(true);
    await expect(config3.fallbackToDevicePasscode).toBe(defaultConfig.fallbackToDevicePasscode);

    final config4 = PowerAuthBiometryConfiguration(fallbackToDevicePasscode: true);
    await expect(config4.authenticateOnBiometricKeySetup).toBe(defaultConfig.authenticateOnBiometricKeySetup);
    await expect(config4.linkItemsToCurrentSet).toBe(defaultConfig.linkItemsToCurrentSet);
    await expect(config4.confirmBiometricAuthentication).toBe(defaultConfig.confirmBiometricAuthentication);
    await expect(config4.fallbackToDevicePasscode).toBe(true);
  }

  Future<void> testKeychainConfiguration() async {
      // Default config
    final defaultConfig = PowerAuthKeychainConfiguration();
    await expect(defaultConfig.minimalRequiredKeychainProtection).toBe(PowerAuthKeychainProtection.none);
    await expect(defaultConfig.accessGroupName).toBeNull();
    await expect(defaultConfig.userDefaultsSuiteName).toBeNull();

    // Now try to build config from some incomplete objects
    final config = PowerAuthKeychainConfiguration(minimalRequiredKeychainProtection: PowerAuthKeychainProtection.strongbox);
    await expect(config.minimalRequiredKeychainProtection).toBe(PowerAuthKeychainProtection.strongbox);

    final config2 = PowerAuthKeychainConfiguration(accessGroupName: "test.accessGroup");
    await expect(config2.accessGroupName).toBe("test.accessGroup");
    await expect(config2.minimalRequiredKeychainProtection).toBe(defaultConfig.minimalRequiredKeychainProtection);
    await expect(config2.userDefaultsSuiteName).toBeNull();

    final config3 = PowerAuthKeychainConfiguration(userDefaultsSuiteName: "SuperDefaults");
    await expect(config3.userDefaultsSuiteName).toBe("SuperDefaults");
    await expect(config3.minimalRequiredKeychainProtection).toBe(defaultConfig.minimalRequiredKeychainProtection);
  }
}