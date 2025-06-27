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
import 'package:flutter_powerauth_mobile_sdk_plugin_example/config.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/suites/test_suite.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/utils/integration_helper.dart';

class PowerAuthConfigureTests extends TestSuite {

  @override 
  getTests() {
    return [testConfigureAndDeconfigure, iosTestActivationSharing, testReconfigureWhileActive, testFullConfiguration];
  }

  @override
  Future<void> afterEach() async {
    await super.afterEach();
    // Cleanup instances
    await cleanupInstances();
  }

  Future<void> testConfigureAndDeconfigure() async {
    
    final pa1 = PowerAuth(instance1);
    final pa2 = PowerAuth(instance2);
    await expect(pa1.instanceId).toBe(instance1);
    await expect(pa2.instanceId).toBe(instance2);

    await expect(pa1.isConfigured()).toBe(false);
    await expect(pa2.isConfigured()).toBe(false);

    // Create helpers. The function also instantiate and configure PowerAuth instance
    final helper1 = await getHelper1();
    final helper2 = await getHelper2();
    // SDK instances from helpers should be available
    final sdk1 = helper1.sdk;
    final sdk2 = helper2.sdk;

    await expect(sdk1.isConfigured()).toBe(true);
    await expect(sdk2.isConfigured()).toBe(true);
    // // Instances created from helper also should have configuration objects set
    await expect(sdk1.configuration).toBeDefined();
    await expect(sdk2.configuration).toBeDefined();
    await expect(sdk1.keychainConfiguration).toBeNull();
    await expect(sdk2.keychainConfiguration).toBeNull();
    await expect(sdk1.clientConfiguration).toBeNull();
    await expect(sdk2.clientConfiguration).toBeNull();
    await expect(sdk1.biometryConfiguration).toBeNull();
    await expect(sdk2.biometryConfiguration).toBeNull();
    await expect(sdk1.sharingConfiguration).toBeNull();
    await expect(sdk2.sharingConfiguration).toBeNull();

    // pa1 & pa2 should be configured now, because PowerAuth is just a thin envelope
    // keeping only essential values
    await expect(await pa1.isConfigured()).toBe(true);
    await expect(await pa2.isConfigured()).toBe(true);
    // Online instances created in helper, pa1 & pa2
    await expect(pa1.configuration).toBeDefined();
    await expect(pa2.configuration).toBeDefined();
    await expect(pa1.keychainConfiguration).toBeNull();
    await expect(pa2.keychainConfiguration).toBeNull();
    await expect(pa1.clientConfiguration).toBeNull();
    await expect(pa2.clientConfiguration).toBeNull();
    await expect(pa1.biometryConfiguration).toBeNull();
    await expect(pa2.biometryConfiguration).toBeNull();
    await expect(pa1.sharingConfiguration).toBeNull();
    await expect(pa2.sharingConfiguration).toBeNull();

    pa1.deconfigure();
    pa2.deconfigure();

    await expect(pa1.isConfigured()).toBe(false);
    await expect(pa2.isConfigured()).toBe(false);
    await expect(sdk1.isConfigured()).toBe(false);
    await expect(sdk2.isConfigured()).toBe(false);
  }

  Future<void> testFullConfiguration() async {
    final helper1 = await getHelper1();
    final sdk1 = helper1.sdk;

    await expect(sdk1.isConfigured()).toBe(true);

    await expect(sdk1.configuration).toBeDefined();
    await expect(sdk1.clientConfiguration).toBeDefined();
    await expect(sdk1.keychainConfiguration).toBeDefined();
    await expect(sdk1.biometryConfiguration).toBeDefined();
    await expect(sdk1.sharingConfiguration).toBeDefined();
  }

  Future<void> iosTestActivationSharing() async {
    if (!Platform.isIOS) {
      print("  🫡 Skipping iOS test on non-iOS platform");
      return;
    }
    final helper1 = await getHelper1();
    final sdk1 = helper1.sdk;
    await expect(sdk1.isConfigured()).toBe(true);
    await expect(sdk1.sharingConfiguration?.appGroup).toBe("group.com.wultra.testGroup");
    await expect(sdk1.sharingConfiguration?.appIdentifier).toBe("SharedInstanceTests");
    await expect(sdk1.sharingConfiguration?.keychainAccessGroup).toBe("fake.accessGroup");
    await expect(sdk1.sharingConfiguration?.sharedMemoryIdentifier).toBe("tst3");
  }

  Future<void> testReconfigureWhileActive() async {
    final helper1 = await getHelper1();
    final sdk1 = helper1.sdk;
    final helper2 = await getHelper2();
    final sdk2 = helper2.sdk;

    await expect(await sdk1.isConfigured()).toBe(true);
    await expect(await sdk2.isConfigured()).toBe(true);

    final config1 = sdk1.configuration;
    final config2 = sdk2.configuration;
    final clientConfig1 = sdk1.clientConfiguration;
    final clientConfig2 = sdk2.clientConfiguration;
    final keychainConfig1 = sdk1.keychainConfiguration;
    final keychainConfig2 = sdk2.keychainConfiguration;
    final biometryConfig1 = sdk1.biometryConfiguration;
    final biometryConfig2 = sdk2.biometryConfiguration;
    final sharingConfig1 = sdk1.sharingConfiguration;
    final sharingConfig2 = sdk2.sharingConfiguration;

    await expect(config1).toBeDefined();
    await expect(config2).toBeDefined();
    await expect(clientConfig1).toBeNull();
    await expect(clientConfig2).toBeNull();
    await expect(keychainConfig1).toBeNull();
    await expect(keychainConfig2).toBeNull();
    await expect(biometryConfig1).toBeNull();
    await expect(biometryConfig2).toBeNull();
    await expect(sharingConfig1).toBeNull();
    await expect(sharingConfig2).toBeNull();

    await helper1.prepareActiveActivation(await getPassword1());
    await helper2.prepareActiveActivation(await getPassword2());

    await expect(sdk1.hasValidActivation()).toBe(true);
    await expect(sdk2.hasValidActivation()).toBe(true);

    await expect(sdk1.validatePassword(await getPassword1())).toSucceed();
    await expect(sdk2.validatePassword(await getPassword2())).toSucceed();

    await sdk1.deconfigure();
    await sdk2.deconfigure();

    // // Now run all methods that must fail while instance is not configured
    await runMethodsThatMustFail(sdk1);
    await runMethodsThatMustFail(sdk2);

    // // Reconfigure. This technically re-create native SDK objects on behalf
    await sdk1.configure(configuration: config1!, clientConfiguration: clientConfig1, biometryConfiguration: biometryConfig1, keychainConfiguration: keychainConfig1);
    await sdk2.configure(configuration: config2!, clientConfiguration: clientConfig2, biometryConfiguration: biometryConfig2, keychainConfiguration: keychainConfig2);

    await expect(sdk1.isConfigured()).toBe(true);
    await expect(sdk2.isConfigured()).toBe(true);

    await expect(sdk1.hasValidActivation()).toBe(true);
    await expect(sdk2.hasValidActivation()).toBe(true);

    await expect(sdk1.validatePassword(await getPassword1())).toSucceed();
    await expect(sdk2.validatePassword(await getPassword2())).toSucceed();

    await expect(sdk1.removeActivationWithAuthentication(PowerAuthAuthentication.password(await getPassword1()))).toSucceed();
    await expect(sdk2.removeActivationWithAuthentication(PowerAuthAuthentication.password(await getPassword2()))).toSucceed();
  }

  // -- HELPERS --

  Future<void> runMethodsThatMustFail(PowerAuth sdk) async {
    final commitAuth = PowerAuthAuthentication.persistWithPassword(await PowerAuthPassword.fromString('1234'));
    final signAuth = PowerAuthAuthentication.possession();
    final emptyPassword = await PowerAuthPassword.fromString('');
    await expect(sdk.hasValidActivation()).toThrow(PowerAuthErrorCode.instanceNotConfigured);
    await expect(sdk.canStartActivation()).toThrow(PowerAuthErrorCode.instanceNotConfigured);
    await expect(sdk.hasPendingActivation()).toThrow(PowerAuthErrorCode.instanceNotConfigured);
    await expect(sdk.fetchActivationStatus()).toThrow(PowerAuthErrorCode.instanceNotConfigured);
    await expect(sdk.createActivation(PowerAuthActivation.fromActivationCode(activationCode: '', name: ''))).toThrow(PowerAuthErrorCode.instanceNotConfigured);
    await expect(sdk.persistActivation(commitAuth)).toThrow(PowerAuthErrorCode.instanceNotConfigured);
    await expect(sdk.getActivationFingerprint()).toThrow(PowerAuthErrorCode.instanceNotConfigured);
    await expect(sdk.getActivationIdentifier()).toThrow(PowerAuthErrorCode.instanceNotConfigured);
    await expect(sdk.removeActivationWithAuthentication(signAuth)).toThrow(PowerAuthErrorCode.instanceNotConfigured);
    await expect(sdk.removeActivationLocal()).toThrow(PowerAuthErrorCode.instanceNotConfigured);
    await expect(sdk.requestGetSignature(signAuth, '', null)).toThrow(PowerAuthErrorCode.instanceNotConfigured);
    await expect(sdk.requestSignature(signAuth, '', '')).toThrow(PowerAuthErrorCode.instanceNotConfigured);
    await expect(sdk.offlineSignature(signAuth, '', '', null)).toThrow(PowerAuthErrorCode.instanceNotConfigured);
    await expect(sdk.verifyServerSignedData('', '', false)).toThrow(PowerAuthErrorCode.instanceNotConfigured);
    await expect(sdk.changePassword(emptyPassword, emptyPassword)).toThrow(PowerAuthErrorCode.instanceNotConfigured);
    await expect(sdk.addBiometryFactor(emptyPassword, null)).toThrow(PowerAuthErrorCode.instanceNotConfigured);
    await expect(sdk.hasBiometryFactor()).toThrow(PowerAuthErrorCode.instanceNotConfigured);
    await expect(sdk.removeBiometryFactor()).toThrow(PowerAuthErrorCode.instanceNotConfigured);
    await expect(sdk.fetchEncryptionKey(signAuth, 1000)).toThrow(PowerAuthErrorCode.instanceNotConfigured);
    await expect(sdk.signDataWithDevicePrivateKey(signAuth, '')).toThrow(PowerAuthErrorCode.instanceNotConfigured);
    await expect(sdk.validatePassword(emptyPassword)).toThrow(PowerAuthErrorCode.instanceNotConfigured);
    await expect(sdk.groupedBiometricAuthentication(signAuth, (auth) async {  })).toThrow(PowerAuthErrorCode.instanceNotConfigured);
    
    // TODO: getBiometryInfo() doesn't depend on configuration. We should move this to separate class
    await expect(PowerAuth.getBiometryInfo()).toSucceed();
  }

  IntegrationHelper? helperInstance1;
  IntegrationHelper? helperInstance2;

  final instance1 = 'testInstance1';
  final instance2 = 'testInstance2';
  Future<PowerAuthPassword> getPassword1() async { return  await PowerAuthPassword.fromString("password1"); }
  Future<PowerAuthPassword> getPassword2() async { return await PowerAuthPassword.fromString("password2"); }
    
  Future<IntegrationHelper> getHelper1() async {
    helperInstance1 ??= await createInstance(instance1);
    return helperInstance1!;
  }

  Future<IntegrationHelper> getHelper2() async {
    
    helperInstance2 ??= await createInstance(instance2);
    return helperInstance2!;
  }

  Future<IntegrationHelper> createInstance(String instanceId) async {
    final helper = IntegrationHelper(PowerAuth(instanceId));
    await _configureSDK(helper);
    return helper;
  }

  Future<void> cleanupInstance(IntegrationHelper? helper) async {
    if (helper == null) {
      return;
    }
    if (await helper.sdk.isConfigured()) {
        await helper.sdk.removeActivationLocal();
        await helper.sdk.deconfigure();
    }
    // await helper?.cleanup();
  }

  Future<void> cleanupInstances() async {
      await cleanupInstance(helperInstance1);
      await cleanupInstance(helperInstance2);
      helperInstance1 = null;
      helperInstance2 = null;
  }

  Future<void> _configureSDK(IntegrationHelper helper) async {

    if (await helper.sdk.isConfigured()) {
      await helper.sdk.deconfigure();
    }

    PowerAuthConfiguration configuration = PowerAuthConfiguration(
      configuration: AppConfig.sdkConfig,
      baseEndpointUrl: AppConfig.enrollmentUrl
    );
    PowerAuthSharingConfiguration? sharingConfig;
    PowerAuthBiometryConfiguration? biometryConfig;
    PowerAuthKeychainConfiguration? keychainConfig;
    PowerAuthClientConfiguration? clientConfig;
    if (currentTestName == 'iosTestActivationSharing') {
      sharingConfig = PowerAuthSharingConfiguration(
        appGroup: "group.com.wultra.testGroup",
        appIdentifier: "SharedInstanceTests",
        keychainAccessGroup: "fake.accessGroup", // This will work only in simulator
        sharedMemoryIdentifier: "tst3"
      );
    }
    if (currentTestName == 'testConfigurationWithBiometry' || currentTestName == 'testFullConfiguration') {
      biometryConfig = PowerAuthBiometryConfiguration(
        authenticateOnBiometricKeySetup: false
      );
    }
    if (currentTestName == 'testFullConfiguration') {
      clientConfig = PowerAuthClientConfiguration();
      keychainConfig = PowerAuthKeychainConfiguration();
      sharingConfig = PowerAuthSharingConfiguration(
        appGroup: "group.com.wultra.testGroup",
        appIdentifier: "SharedInstanceTests",
        keychainAccessGroup: "fake.accessGroup", // This will work only in simulator
        sharedMemoryIdentifier: "tst4"
      );
    }
    await helper.sdk.configure(
      configuration: configuration, 
      clientConfiguration: clientConfig, 
      biometryConfiguration: biometryConfig, 
      keychainConfiguration: keychainConfig, 
      sharingConfiguration: sharingConfig
      );
  }
}