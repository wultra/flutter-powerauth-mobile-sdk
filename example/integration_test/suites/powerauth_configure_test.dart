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
import '../utils/integration_helper.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_powerauth_mobile_sdk_plugin_example/config.dart';

/// Removes a single trailing slash from [url].
String _normalizeEndpointUrl(String url) =>
    url.endsWith('/') ? url.substring(0, url.length - 1) : url;

main() {
  group('Configure tests', () {
    IntegrationHelper? helperInstance1;
    IntegrationHelper? helperInstance2;

    final instance1 = 'testInstance1';
    final instance2 = 'testInstance2';

    Future<PowerAuthPassword> getPassword1() async {
      return await PowerAuthPassword.fromString("password1");
    }

    Future<PowerAuthPassword> getPassword2() async {
      return await PowerAuthPassword.fromString("password2");
    }

    Future<void> cleanupInstance(IntegrationHelper? helper) async {
      if (helper == null) {
        return;
      }
      if (await helper.sdk.isConfigured()) {
        await helper.sdk.removeActivationLocal();
        await helper.sdk.deconfigure();
      }
      // await helper.cleanup();
    }

    Future<void> cleanupInstances() async {
      await cleanupInstance(helperInstance1);
      await cleanupInstance(helperInstance2);
      helperInstance1 = null;
      helperInstance2 = null;
    }

    setUp(() async {
      await AppConfig.ensureLoaded();
    });

    tearDown(() async {
      await cleanupInstances();
    });

    Future<void> configureSDK(
      IntegrationHelper helper,
      String currentTestName,
    ) async {
      if (await helper.sdk.isConfigured()) {
        await helper.sdk.deconfigure();
      }

      PowerAuthConfiguration configuration = PowerAuthConfiguration(
        configuration: AppConfig.sdkConfig,
        baseEndpointUrl: AppConfig.enrollmentUrl,
      );
      PowerAuthSharingConfiguration? sharingConfig;
      PowerAuthBiometryConfiguration? biometryConfig;
      PowerAuthKeychainConfiguration? keychainConfig;
      PowerAuthClientConfiguration? clientConfig;
      if (currentTestName == 'iosTestActivationSharing') {
        sharingConfig = PowerAuthSharingConfiguration(
          appGroup: "group.com.wultra.testGroup",
          appIdentifier: "SharedInstanceTests",
          keychainAccessGroup:
              "fake.accessGroup", // This will work only in simulator
          sharedMemoryIdentifier: "tst3",
        );
      }
      if (currentTestName == 'testConfigurationWithBiometry' ||
          currentTestName == 'testFullConfiguration') {
        biometryConfig = PowerAuthBiometryConfiguration(
          authenticateOnBiometricKeySetup: false,
        );
      }
      if (currentTestName == 'testFullConfiguration') {
        clientConfig = PowerAuthClientConfiguration();
        keychainConfig = PowerAuthKeychainConfiguration();
        sharingConfig = PowerAuthSharingConfiguration(
          appGroup: "group.com.wultra.testGroup",
          appIdentifier: "SharedInstanceTests",
          keychainAccessGroup:
              "fake.accessGroup", // This will work only in simulator
          sharedMemoryIdentifier: "tst4",
        );
      }
      await helper.sdk.configure(
        configuration: configuration,
        clientConfiguration: clientConfig,
        biometryConfiguration: biometryConfig,
        keychainConfiguration: keychainConfig,
        sharingConfiguration: sharingConfig,
      );
    }

    Future<IntegrationHelper> createInstance(
      String instanceId,
      String testName,
    ) async {
      final helper = IntegrationHelper(PowerAuth(instanceId));
      await configureSDK(helper, testName);
      return helper;
    }

    Future<IntegrationHelper> getHelper1(String testName) async {
      helperInstance1 ??= await createInstance(instance1, testName);
      return helperInstance1!;
    }

    Future<IntegrationHelper> getHelper2(String testName) async {
      helperInstance2 ??= await createInstance(instance2, testName);
      return helperInstance2!;
    }

    Future<void> runMethodsThatMustFail(PowerAuth sdk) async {
      final commitAuth = PowerAuthAuthentication.persistWithPassword(
        await PowerAuthPassword.fromString('1234'),
      );
      final signAuth = PowerAuthAuthentication.possession();
      final emptyPassword = await PowerAuthPassword.fromString('');

      await expectLater(
        sdk.hasValidActivation(),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.instanceNotConfigured,
          ),
        ),
      );
      await expectLater(
        sdk.canStartActivation(),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.instanceNotConfigured,
          ),
        ),
      );
      await expectLater(
        sdk.hasPendingActivation(),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.instanceNotConfigured,
          ),
        ),
      );
      await expectLater(
        sdk.fetchActivationStatus(),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.instanceNotConfigured,
          ),
        ),
      );
      await expectLater(
        sdk.createActivation(
          PowerAuthActivation.fromActivationCode(activationCode: '', name: ''),
        ),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.instanceNotConfigured,
          ),
        ),
      );
      await expectLater(
        sdk.persistActivation(commitAuth),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.instanceNotConfigured,
          ),
        ),
      );
      await expectLater(
        sdk.getActivationFingerprint(),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.instanceNotConfigured,
          ),
        ),
      );
      await expectLater(
        sdk.getActivationIdentifier(),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.instanceNotConfigured,
          ),
        ),
      );
      await expectLater(
        sdk.removeActivationWithAuthentication(signAuth),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.instanceNotConfigured,
          ),
        ),
      );
      await expectLater(
        sdk.removeActivationLocal(),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.instanceNotConfigured,
          ),
        ),
      );
      await expectLater(
        sdk.requestGetSignature(signAuth, '', null),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.instanceNotConfigured,
          ),
        ),
      );
      await expectLater(
        sdk.requestSignature(signAuth, '', ''),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.instanceNotConfigured,
          ),
        ),
      );
      await expectLater(
        sdk.offlineSignature(signAuth, '', '', null),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.instanceNotConfigured,
          ),
        ),
      );
      await expectLater(
        sdk.verifyServerSignedData('', '', false),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.instanceNotConfigured,
          ),
        ),
      );
      await expectLater(
        sdk.changePassword(emptyPassword, emptyPassword),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.instanceNotConfigured,
          ),
        ),
      );
      await expectLater(
        sdk.addBiometryFactor(emptyPassword, null),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.instanceNotConfigured,
          ),
        ),
      );
      await expectLater(
        sdk.removeBiometryFactor(),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.instanceNotConfigured,
          ),
        ),
      );
      await expectLater(
        sdk.fetchEncryptionKey(signAuth, 1000),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.instanceNotConfigured,
          ),
        ),
      );
      await expectLater(
        sdk.signDataWithDevicePrivateKey(signAuth, ''),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.instanceNotConfigured,
          ),
        ),
      );
      await expectLater(
        sdk.validatePassword(emptyPassword),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.instanceNotConfigured,
          ),
        ),
      );
      await expectLater(
        sdk.groupedBiometricAuthentication(signAuth, (auth) async {}),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.instanceNotConfigured,
          ),
        ),
      );

      await expectLater(
        sdk.configuration,
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.instanceNotConfigured,
          ),
        ),
      );

      // TODO: getBiometryInfo() doesn't depend on configuration. We should move this to separate class
      await expectLater(PowerAuth.getBiometryInfo(), completes);
    }

    test('testConfigureAndDeconfigure', () async {
      final pa1 = PowerAuth(instance1);
      final pa2 = PowerAuth(instance2);
      expect(pa1.instanceId, instance1);
      expect(pa2.instanceId, instance2);

      expect(await pa1.isConfigured(), false);
      expect(await pa2.isConfigured(), false);
      final helper1 = await getHelper1('');
      final helper2 = await getHelper2('');
      final sdk1 = helper1.sdk;
      final sdk2 = helper2.sdk;

      expect(await sdk1.isConfigured(), true);
      expect(await sdk2.isConfigured(), true);
      final sdk1Config = await sdk1.configuration;
      final sdk2Config = await sdk2.configuration;
      expect(sdk1Config, isNotNull);
      expect(sdk2Config, isNotNull);
      expect(
        _normalizeEndpointUrl(sdk1Config!.baseEndpointUrl),
        _normalizeEndpointUrl(AppConfig.enrollmentUrl),
      );
      expect(
        _normalizeEndpointUrl(sdk2Config!.baseEndpointUrl),
        _normalizeEndpointUrl(AppConfig.enrollmentUrl),
      );
      expect(sdk1Config.configuration, AppConfig.sdkConfig);
      expect(sdk2Config.configuration, AppConfig.sdkConfig);

      // TEMP: will be fixed in version 2.0.0 SDK
      // expect(await sdk1.keychainConfiguration, expectedValueOptionalFields);
      // expect(await sdk2.keychainConfiguration, expectedValueOptionalFields);
      // expect(await sdk1.clientConfiguration, expectedValueOptionalFields);
      // expect(await sdk2.clientConfiguration, expectedValueOptionalFields);
      // expect(await sdk1.biometryConfiguration, expectedValueOptionalFields);
      // expect(await sdk2.biometryConfiguration, expectedValueOptionalFields);
      // expect(await sdk1.sharingConfiguration, isNull);
      // expect(await sdk2.sharingConfiguration, isNull);
      expect(await pa1.isConfigured(), true);
      expect(await pa2.isConfigured(), true);
      final pa1Config = await pa1.configuration;
      final pa2Config = await pa2.configuration;
      expect(pa1Config, isNotNull);
      expect(pa2Config, isNotNull);
      expect(
        _normalizeEndpointUrl(pa1Config!.baseEndpointUrl),
        _normalizeEndpointUrl(AppConfig.enrollmentUrl),
      );
      expect(
        _normalizeEndpointUrl(pa2Config!.baseEndpointUrl),
        _normalizeEndpointUrl(AppConfig.enrollmentUrl),
      );

      // TEMP: will be fixed in version 2.0.0 SDK
      // expect(await pa1.keychainConfiguration, expectedValueOptionalFields);
      // expect(await pa2.keychainConfiguration, expectedValueOptionalFields);
      // expect(await pa1.clientConfiguration, expectedValueOptionalFields);
      // expect(await pa2.clientConfiguration, expectedValueOptionalFields);
      // expect(await pa1.biometryConfiguration, expectedValueOptionalFields);
      // expect(await pa2.biometryConfiguration, expectedValueOptionalFields);
      // expect(await pa1.sharingConfiguration, isNull);
      // expect(await pa2.sharingConfiguration, isNull);

      await pa1.deconfigure();
      await pa2.deconfigure();

      expect(await pa1.isConfigured(), false);
      expect(await pa2.isConfigured(), false);
      expect(await sdk1.isConfigured(), false);
      expect(await sdk2.isConfigured(), false);
      await expectLater(
        pa1.configuration,
        throwsA(isA<PowerAuthException>().having(
          (e) => e.code, "code", PowerAuthErrorCode.instanceNotConfigured,
        )),
      );
      await expectLater(
        pa2.configuration,
        throwsA(isA<PowerAuthException>().having(
          (e) => e.code, "code", PowerAuthErrorCode.instanceNotConfigured,
        )),
      );
      await expectLater(
        sdk1.configuration,
        throwsA(isA<PowerAuthException>().having(
          (e) => e.code, "code", PowerAuthErrorCode.instanceNotConfigured,
        )),
      );
      await expectLater(
        sdk2.configuration,
        throwsA(isA<PowerAuthException>().having(
          (e) => e.code, "code", PowerAuthErrorCode.instanceNotConfigured,
        )),
      );

    });

    test('testFullConfiguration', () async {
      final helper1 = await getHelper1('testFullConfiguration');
      final sdk1 = helper1.sdk;

      expect(await sdk1.isConfigured(), true);

      expect(await sdk1.configuration, isNotNull);

      // TEMP: will be fixed in version 2.0.0 SDK
      // expect(sdk1.clientConfiguration, isNotNull);
      // expect(sdk1.keychainConfiguration, isNotNull);
      // expect(sdk1.biometryConfiguration, isNotNull);
      // expect(sdk1.sharingConfiguration, isNotNull);
    });

    test('iosTestActivationSharing', () async {
      // if (!Platform.isIOS) {
      //   print("  🫡 Skipping iOS test on non-iOS platform");
      //   return;
      // }
      final helper1 = await getHelper1('iosTestActivationSharing');
      final sdk1 = helper1.sdk;
      expect(await sdk1.isConfigured(), true);

      // TEMP: will be fixed in version 2.0.0 SDK
      // expect((await sdk1.sharingConfiguration)?.appGroup, "group.com.wultra.testGroup");
      // expect((await sdk1.sharingConfiguration)?.appIdentifier, "SharedInstanceTests");
      // expect(
      //   (await sdk1.sharingConfiguration)?.keychainAccessGroup,
      //   "fake.accessGroup",
      // );
      // expect((await sdk1.sharingConfiguration)?.sharedMemoryIdentifier, "tst3");
    }, skip: !Platform.isIOS);

    test('testReconfigureWhileActive', () async {
      final helper1 = await getHelper1('');
      final sdk1 = helper1.sdk;
      final helper2 = await getHelper2('');
      final sdk2 = helper2.sdk;

      expect(await sdk1.isConfigured(), true);
      expect(await sdk2.isConfigured(), true);

      final config1 = await sdk1.configuration;
      final config2 = await sdk2.configuration;

      // TEMP: will be fixed in version 2.0.0 SDK
      // final clientConfig1 = await sdk1.clientConfiguration;
      // final clientConfig2 = await sdk2.clientConfiguration;
      // final keychainConfig1 = await sdk1.keychainConfiguration;
      // final keychainConfig2 = await sdk2.keychainConfiguration;
      // final biometryConfig1 = await sdk1.biometryConfiguration;
      // final biometryConfig2 = await sdk2.biometryConfiguration;
      // final sharingConfig1 = await sdk1.sharingConfiguration;
      // final sharingConfig2 = await sdk2.sharingConfiguration;

      expect(config1, isNotNull);
      expect(config2, isNotNull);

      // TEMP: will be fixed in version 2.0.0 SDK
      // expect(clientConfig1, expectedValueOptionalFields);
      // expect(clientConfig2, expectedValueOptionalFields);
      // expect(keychainConfig1, expectedValueOptionalFields);
      // expect(keychainConfig2, expectedValueOptionalFields);
      // expect(biometryConfig1, expectedValueOptionalFields);
      // expect(biometryConfig2, expectedValueOptionalFields);
      // expect(sharingConfig1, isNull);
      // expect(sharingConfig2, isNull);

      await helper1.prepareActiveActivation(await getPassword1());
      await helper2.prepareActiveActivation(await getPassword2());

      expect(await sdk1.hasValidActivation(), true);
      expect(await sdk2.hasValidActivation(), true);

      await expectLater(
        helper1.sdk.validatePassword(await getPassword1()),
        completes,
      );
      await expectLater(
        helper2.sdk.validatePassword(await getPassword2()),
        completes,
      );

      await helper1.sdk.deconfigure();
      await helper2.sdk.deconfigure();

      // Now run all methods that must fail while instance is not configured
      await runMethodsThatMustFail(helper1.sdk);
      await runMethodsThatMustFail(helper2.sdk);

      // Reconfigure. This technically re-create native SDK objects on behalf
      await helper1.sdk.configure(
        configuration: config1!,
        // TEMP: will be fixed in version 2.0.0 SDK
        // clientConfiguration: clientConfig1,
        // biometryConfiguration: biometryConfig1,
        // keychainConfiguration: keychainConfig1,
      );
      await helper2.sdk.configure(
        configuration: config2!,
        // TEMP: will be fixed in version 2.0.0 SDK
        // clientConfiguration: clientConfig2,
        // biometryConfiguration: biometryConfig2,
        // keychainConfiguration: keychainConfig2,
      );

      expect(await helper1.sdk.isConfigured(), true);
      expect(await helper2.sdk.isConfigured(), true);

      expect(await helper1.sdk.hasValidActivation(), true);
      expect(await helper2.sdk.hasValidActivation(), true);

      await expectLater(
        helper1.sdk.validatePassword(await getPassword1()),
        completes,
      );
      await expectLater(
        helper2.sdk.validatePassword(await getPassword2()),
        completes,
      );

      await expectLater(
        helper1.sdk.removeActivationWithAuthentication(
          PowerAuthAuthentication.password(await getPassword1()),
        ),
        completes,
      );
      await expectLater(
        helper2.sdk.removeActivationWithAuthentication(
          PowerAuthAuthentication.password(await getPassword2()),
        ),
        completes,
      );
    });
  });
}
