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
import '../utils/helper_functions.dart';
import '../utils/integration_helper.dart';

import '../utils/native_test.dart';

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

    Future<void> validatePassword(
      PowerAuth sdk,
      PowerAuthPassword password,
    ) async {
      final changeData = await sdk.beginPasswordChange(password);
      await changeData.release();
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
        offlineAuthenticationCodeComponentLength: 6,
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
        keychainConfig =
            Platform.isAndroid ? PowerAuthKeychainConfiguration() : null;
        sharingConfig =
            Platform.isIOS
                ? PowerAuthSharingConfiguration(
                  appGroup: "group.com.wultra.testGroup",
                  appIdentifier: "SharedInstanceTests",
                  keychainAccessGroup:
                      "fake.accessGroup", // Simulator-only fixture.
                )
                : null;
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
      final expected = throwsPowerAuthCode(
        PowerAuthErrorCode.instanceNotConfigured,
      );
      final commitAuth = PowerAuthAuthentication.persistWithPassword(
        await PowerAuthPassword.fromString('1234'),
      );
      final signAuth = PowerAuthAuthentication.possession();
      final emptyPassword = await PowerAuthPassword.fromString('');
      // Test-only wrapper used to prove finish checks configuration first.
      // ignore: invalid_use_of_internal_member
      final changeData = PowerAuthPasswordChangeData.fromNative(
        objectId: 'not-configured-change-data',
      );

      try {
        await expectLater(sdk.configuration, expected);
        await expectLater(sdk.currentAlgorithm, expected);
        await expectLater(sdk.hasValidActivation(), expected);
        await expectLater(sdk.canStartActivation(), expected);
        await expectLater(sdk.hasPendingActivation(), expected);
        await expectLater(sdk.fetchActivationStatus(), expected);
        await expectLater(sdk.hasProtocolUpgradeAvailable(), expected);
        await expectLater(sdk.hasPendingProtocolUpgrade(), expected);
        await expectLater(sdk.startProtocolUpgrade(emptyPassword), expected);
        await expectLater(
          sdk.createActivation(
            PowerAuthActivation.fromActivationCode(
              activationCode: '',
              name: '',
            ),
          ),
          expected,
        );
        await expectLater(sdk.persistActivation(commitAuth), expected);
        await expectLater(sdk.getActivationFingerprint(), expected);
        await expectLater(sdk.getActivationIdentifier(), expected);
        await expectLater(
          sdk.removeActivationWithAuthentication(signAuth),
          expected,
        );
        await expectLater(sdk.removeActivationLocal(), expected);
        await expectLater(
          sdk.authenticationHeaderForRequestWithParams(
            signAuth,
            'GET',
            '/test',
          ),
          expected,
        );
        await expectLater(
          sdk.authenticationHeaderForRequestWithBody(
            signAuth,
            'POST',
            '/test',
            utf8Bytes('{}'),
          ),
          expected,
        );
        await expectLater(
          sdk.offlineSignature(signAuth, '/test', 'MDEyMzQ1Njc='),
          expected,
        );
        await expectLater(sdk.beginPasswordChange(emptyPassword), expected);
        await expectLater(
          sdk.finishPasswordChange(emptyPassword, changeData),
          expected,
        );
        await expectLater(
          sdk.verifyDigitalSignature(
            utf8Bytes('signature'),
            utf8Bytes('data'),
            PowerAuthSignatureKeyId.serverEc,
          ),
          expected,
        );
        await expectLater(
          sdk.calculateDigitalSignature(
            signAuth,
            utf8Bytes('data'),
            PowerAuthSignatureKeyId.deviceEc,
          ),
          expected,
        );
        await expectLater(
          sdk.exportDevicePublicKeys(PowerAuthDevicePublicKeyFormat.der),
          expected,
        );
        await expectLater(
          sdk.verifyJwsSignature(
            'invalid',
            true,
            true,
            PowerAuthSignatureKeyId.serverEc,
          ),
          expected,
        );
        await expectLater(
          sdk.calculateJwsSignature(
            signAuth,
            utf8Bytes('data'),
            null,
            true,
            PowerAuthSignatureKeyId.deviceEc,
          ),
          expected,
        );
        await expectLater(
          sdk.createCertificateSigningRequest(
            signAuth,
            {'CN': 'test'},
            null,
            PowerAuthSignatureKeyId.deviceEc,
          ),
          expected,
        );
        await expectLater(sdk.addBiometryFactor(emptyPassword), expected);
        await expectLater(sdk.hasBiometryFactor(), expected);
        await expectLater(sdk.getBiometricStatus(), expected);
        await expectLater(
          sdk.isAuthenticationWithBiometricsAvailable(),
          expected,
        );
        await expectLater(sdk.removeBiometryFactor(), expected);
        await expectLater(
          sdk.fetchSecureVaultKey(
            signAuth,
            PowerAuthSecureVaultKeyId.knowledge,
          ),
          expected,
        );
        await expectLater(
          sdk.groupedBiometricAuthentication(signAuth, (auth) async {}),
          expected,
        );
        await expectLater(sdk.getEncryptorForApplicationScope(), expected);
        await expectLater(sdk.getEncryptorForActivationScope(), expected);
        await expectLater(sdk.fetchUserInfo(), expected);
        await expectLater(sdk.getLastFetchedUserInfo(), expected);
        await expectLater(sdk.tokenStore.hasLocalToken('test'), expected);
        await expectLater(sdk.tokenStore.getLocalToken('test'), expected);
        await expectLater(sdk.tokenStore.removeLocalToken('test'), expected);
        await expectLater(sdk.tokenStore.removeAllLocalTokens(), expected);
        await expectLater(
          sdk.tokenStore.requestAccessToken('test', signAuth),
          expected,
        );
        await expectLater(sdk.tokenStore.removeAccessToken('test'), expected);
        await expectLater(
          sdk.tokenStore.generateHeaderForToken('test'),
          expected,
        );
        await expectLater(
          sdk.timeSynchronizationService.isTimeSynchronized(),
          expected,
        );
        await expectLater(
          sdk.timeSynchronizationService.currentTime(),
          expected,
        );
        await expectLater(
          sdk.timeSynchronizationService.synchronizeTime(),
          expected,
        );
        await expectLater(
          sdk.timeSynchronizationService.resetTimeSynchronization(),
          expected,
        );
        await expectLater(
          sdk.timeSynchronizationService.localTimeAdjustment(),
          expected,
        );
        await expectLater(
          sdk.timeSynchronizationService.localTimeAdjustmentPrecision(),
          expected,
        );
      } finally {
        await emptyPassword.release();
        await commitAuth.password?.release();
        await changeData.release();
      }
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
        _normalizeEndpointUrl(sdk1Config.baseEndpointUrl),
        _normalizeEndpointUrl(AppConfig.enrollmentUrl),
      );
      expect(
        _normalizeEndpointUrl(sdk2Config.baseEndpointUrl),
        _normalizeEndpointUrl(AppConfig.enrollmentUrl),
      );
      expect(sdk1Config.configuration, AppConfig.sdkConfig);
      expect(sdk2Config.configuration, AppConfig.sdkConfig);
      expect(sdk1Config.offlineAuthenticationCodeComponentLength, 6);
      expect(sdk2Config.offlineAuthenticationCodeComponentLength, 6);
      expect(sdk1Config.algorithm, await sdk1.currentAlgorithm);
      expect(sdk2Config.algorithm, await sdk2.currentAlgorithm);

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
        _normalizeEndpointUrl(pa1Config.baseEndpointUrl),
        _normalizeEndpointUrl(AppConfig.enrollmentUrl),
      );
      expect(
        _normalizeEndpointUrl(pa2Config.baseEndpointUrl),
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
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.instanceNotConfigured,
          ),
        ),
      );
      await expectLater(
        pa2.configuration,
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.instanceNotConfigured,
          ),
        ),
      );
      await expectLater(
        sdk1.configuration,
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.instanceNotConfigured,
          ),
        ),
      );
      await expectLater(
        sdk2.configuration,
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.instanceNotConfigured,
          ),
        ),
      );
    });

    test('testFullConfiguration', () async {
      final helper1 = await getHelper1('testFullConfiguration');
      final sdk1 = helper1.sdk;

      expect(await sdk1.isConfigured(), true);

      final configuration = await sdk1.configuration;
      expect(configuration.offlineAuthenticationCodeComponentLength, 6);
      expect(configuration.algorithm, await sdk1.currentAlgorithm);

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

      await validatePassword(helper1.sdk, await getPassword1());
      await validatePassword(helper2.sdk, await getPassword2());

      await helper1.sdk.deconfigure();
      await helper2.sdk.deconfigure();

      // Now run all methods that must fail while instance is not configured
      await runMethodsThatMustFail(helper1.sdk);
      await runMethodsThatMustFail(helper2.sdk);

      // Reconfigure. This technically re-create native SDK objects on behalf
      await helper1.sdk.configure(
        configuration: config1,
        // TEMP: will be fixed in version 2.0.0 SDK
        // clientConfiguration: clientConfig1,
        // biometryConfiguration: biometryConfig1,
        // keychainConfiguration: keychainConfig1,
      );
      await helper2.sdk.configure(
        configuration: config2,
        // TEMP: will be fixed in version 2.0.0 SDK
        // clientConfiguration: clientConfig2,
        // biometryConfiguration: biometryConfig2,
        // keychainConfiguration: keychainConfig2,
      );

      expect(await helper1.sdk.isConfigured(), true);
      expect(await helper2.sdk.isConfigured(), true);

      expect(await helper1.sdk.hasValidActivation(), true);
      expect(await helper2.sdk.hasValidActivation(), true);

      await validatePassword(helper1.sdk, await getPassword1());
      await validatePassword(helper2.sdk, await getPassword2());

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
