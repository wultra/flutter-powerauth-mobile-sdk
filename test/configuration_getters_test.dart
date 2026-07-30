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

import 'package:flutter/services.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('powerauth_plugin');
  final calls = <MethodCall>[];
  final sdk = PowerAuth('configuration-getters');

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return switch (call.method) {
            'getClientConfiguration' => <String, dynamic>{
              'enableUnsecureTraffic': true,
              'connectionTimeout': 12.5,
              'readTimeout': 17.0,
            },
            'getBiometryConfiguration' => <String, dynamic>{
              'invalidateBiometricFactorAfterChange': false,
              'fallbackToDevicePasscode': true,
              'confirmBiometricAuthentication': true,
              'authenticateOnBiometricKeySetup': false,
              'fallbackToSharedBiometryKey': false,
              'useLegacySymmetricKey': true,
            },
            'getKeychainConfiguration' => <String, dynamic>{
              'minimalRequiredKeychainProtection': 'hardware',
            },
            'getSharingConfiguration' => <String, dynamic>{
              'appGroup': 'group.com.example.shared',
              'appIdentifier': 'com.example.app',
              'keychainAccessGroup': 'TEAMID.com.example.shared',
            },
            _ => null,
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('restores all effective native configurations', () async {
    final client = await sdk.clientConfiguration;
    final biometry = await sdk.biometryConfiguration;
    final keychain = await sdk.keychainConfiguration;
    final sharing = await sdk.sharingConfiguration;

    expect(client.enableUnsecureTraffic, isTrue);
    expect(client.connectionTimeout, 12.5);
    expect(client.readTimeout, 17.0);

    expect(biometry.invalidateBiometricFactorAfterChange, isFalse);
    expect(biometry.fallbackToDevicePasscode, isTrue);
    expect(biometry.confirmBiometricAuthentication, isTrue);
    expect(biometry.authenticateOnBiometricKeySetup, isFalse);
    expect(biometry.fallbackToSharedBiometryKey, isFalse);
    expect(biometry.useLegacySymmetricKey, isTrue);

    expect(
      keychain?.minimalRequiredKeychainProtection,
      PowerAuthKeychainProtection.hardware,
    );
    expect(sharing?.appGroup, 'group.com.example.shared');
    expect(sharing?.appIdentifier, 'com.example.app');
    expect(sharing?.keychainAccessGroup, 'TEAMID.com.example.shared');

    expect(calls.map((call) => call.method), [
      'getClientConfiguration',
      'getBiometryConfiguration',
      'getKeychainConfiguration',
      'getSharingConfiguration',
    ]);
    for (final call in calls) {
      expect(call.arguments, {'instanceId': 'configuration-getters'});
    }
  });

  test('preserves null for platform-specific configurations', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);

    expect(await sdk.keychainConfiguration, isNull);
    expect(await sdk.sharingConfiguration, isNull);
  });
}
