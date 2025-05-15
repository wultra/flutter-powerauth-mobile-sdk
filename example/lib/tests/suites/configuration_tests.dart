
import 'dart:io';

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin_example/config.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/suites/test_suite.dart';

class ConfigurationTests extends TestSuite {

  @override 
  getTests() {
    return [testConfigureAndDeconfigure, iosTestActivationSharing];
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
    final sdk1 = helper1.powerAuthSdk!;
    final sdk2 = helper2.powerAuthSdk!;

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

  Future<void> iosTestActivationSharing() async {
    if (!Platform.isIOS) {
      print("Skipping iOS test on non-iOS platform");
      return;
    }
    final helper1 = await getHelper1();
    final sdk1 = helper1.powerAuthSdk!;
    await expect(sdk1.isConfigured()).toBe(true);
    await expect(sdk1.sharingConfiguration?.appGroup).toBe("group.com.wultra.testGroup");
    await expect(sdk1.sharingConfiguration?.appIdentifier).toBe("SharedInstanceTests");
    await expect(sdk1.sharingConfiguration?.keychainAccessGroup).toBe("fake.accessGroup");
    await expect(sdk1.sharingConfiguration?.sharedMemoryIdentifier).toBe("tst3");
  }

  ActivationHelper? helperInstance1;
  ActivationHelper? helperInstance2;

  final instance1 = 'testInstance1';
  final instance2 = 'testInstance2';
  final password1 = 'SueprSecure';
  final password2 = 'GoodAlternative';

  Future<ActivationHelper> getHelper1() async {
    helperInstance1 ??= await createInstance(instance1);
    return helperInstance1!;
  }

  Future<ActivationHelper> getHelper2() async {
    
    helperInstance2 ??= await createInstance(instance2);
    return helperInstance2!;
  }

  Future<ActivationHelper> createInstance(String instanceId) async {
    final helper = ActivationHelper(); //await createActivationHelper(this.serverApi, this.config, activation => this.customizePowerAuthActivation(activation))
    //await helper.getPowerAuthSdk(this.prepareData(instanceId))
    helper.powerAuthSdk = await createSDK(prepareData(instanceId));
    return helper;
  }

  Future<PowerAuth> createSDK(CustomActivationHelperPrepareData pd) async {
    // Prepare instanceId. We're using custom data in prepare interface to keep instance id.
    final instanceId = pd.powerAuthInstanceId ?? 'default';
    final sdk = PowerAuth(instanceId);
    if (await sdk.isConfigured()) {
        sdk.deconfigure();
    }
    // Use configuration objects
    final instanceConfig = pd.instanceConfig ?? PowerAuthConfiguration(configuration: AppConfig.powerAuthConfigString, baseEndpointUrl: AppConfig.baseUrl);
    await sdk.configure(
      configuration: instanceConfig, 
      clientConfiguration: pd.clientConfig,
      biometryConfiguration: pd.biometryConfig,
      keychainConfiguration: pd.keychainConfig,
      sharingConfiguration: pd.sharingConfiguration
    );
    return sdk;
  }

  Future<void> cleanupInstance(ActivationHelper? helper, String instanceId) async {
    final sdk = PowerAuth(instanceId);
    if (await sdk.isConfigured()) {
        await sdk.removeActivationLocal();
        sdk.deconfigure();
    }
    await helper?.cleanup();
  }

  Future<void> cleanupInstances() async {
      await cleanupInstance(helperInstance1, instance1);
      await cleanupInstance(helperInstance2, instance2);
      helperInstance1 = null;
      helperInstance2 = null;
  }

    // customizePowerAuthActivation(activation: PowerAuthActivation) {}

  CustomActivationHelperPrepareData prepareData(String instanceId) {
    final data = CustomActivationHelperPrepareData();
    data.powerAuthInstanceId = instanceId;
    data.password = instanceId == instance1 ? password1 : password2;
    if (currentTestName == 'iosTestActivationSharing') {
      data.sharingConfiguration = PowerAuthSharingConfiguration(
        appGroup: "group.com.wultra.testGroup",
        appIdentifier: "SharedInstanceTests",
        keychainAccessGroup: "fake.accessGroup", // This will work only in simulator
        sharedMemoryIdentifier: "tst3"
      );
    } else if (currentTestName == 'testConfigurationWithBiometry') {
      data.biometryConfig = PowerAuthBiometryConfiguration(
        authenticateOnBiometricKeySetup: false
      );
    }
    return data;
  }
}

class ActivationHelper {
  PowerAuth? powerAuthSdk;

  Future<void> cleanup() async {
    // Cleanup logic here
  }
}

class CustomActivationHelperPrepareData extends ActivationHelperPrepareData {
    /// If provided, then overrides instance identifier from TestConfig
    String? powerAuthInstanceId;
    
    /// If provided, then `PowerAuth` object will be configured with this configuration, instead of the default one.
    PowerAuthConfiguration? instanceConfig;
    
    /// If provided, then this client configuration will be applied to PowerAuth instance.
    /// Note that the configuration will be ignored if `useConfigObjects` is false and `instanceConfig` is undefined. 
    PowerAuthClientConfiguration? clientConfig;
    
    /// If provided, then this keychain configuration will be applied to PowerAuth instance.
    /// Note that the configuration will be ignored if `useConfigObjects` is false and `instanceConfig` is undefined. 
    PowerAuthKeychainConfiguration? keychainConfig;
    
    /// If provided, then this biometry configuration will be applied to PowerAuth instance.
    /// Note that the configuration will be ignored if `useConfigObjects` is false and `instanceConfig` is undefined. 
    PowerAuthBiometryConfiguration? biometryConfig;
    
    /// If provided, then this sharing configuration will be applied to PowerAuth instance.
    /// Note that the configuration will be ignored if `useConfigObjects` is false and `instanceConfig` is undefined.
    PowerAuthSharingConfiguration? sharingConfiguration;
}

class ActivationHelperPrepareData {
    /// Password for knowledge factor
    String? password;
    /// Information whether activation will use also biometry factor.
    bool? useBiometry;
    /// OTP in case of OTP validaiton.
    String? otp;
    /// OTP validation mode.
    // ActivationOtpValidation? otpValidation;
}