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
import 'package:flutter_powerauth_mobile_sdk_plugin/src/model/powerauth_authentication_internal.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/src/powerauth/powerauth_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

class _BiometricPlatform extends PowerAuthPlatform {
  bool configured = true;
  int resolveCount = 0;
  bool? makeReusable;
  String? resolvedInstanceId;

  @override
  Future<bool> isConfigured(String instanceId) async => configured;

  @override
  Future<PowerAuthAuthentication> resolveAuthentication(
    String instanceId,
    PowerAuthAuthentication authentication, {
    bool makeReusable = false,
  }) async {
    resolveCount++;
    resolvedInstanceId = instanceId;
    this.makeReusable = makeReusable;
    final internal = authentication as InternalAuth;
    internal.isReusable = makeReusable;
    internal.biometryKeyId = internal.useBiometry ? 'biometry-key' : null;
    return internal;
  }
}

void main() {
  late PowerAuthPlatform originalPlatform;
  late _BiometricPlatform platform;
  late PowerAuth sdk;

  setUp(() {
    originalPlatform = PowerAuthPlatform.instance;
    platform = _BiometricPlatform();
    PowerAuthPlatform.instance = platform;
    sdk = PowerAuth('biometric-instance');
  });

  tearDown(() {
    PowerAuthPlatform.instance = originalPlatform;
  });

  test('resolves once and exposes only the reusable authentication', () async {
    final authentication = PowerAuthAuthentication.biometry(
      biometricPrompt: PowerAuthBiometricPrompt(promptMessage: 'Authenticate'),
    );
    PowerAuthAuthentication? callbackAuthentication;
    var callbackCount = 0;

    await sdk.groupedBiometricAuthentication(authentication, (resolved) async {
      callbackCount++;
      callbackAuthentication = resolved;
      final internal = resolved as InternalAuth;
      expect(internal.isReusable, isTrue);
      expect(internal.biometryKeyId, 'biometry-key');
    });

    expect(platform.resolveCount, 1);
    expect(platform.resolvedInstanceId, 'biometric-instance');
    expect(platform.makeReusable, isTrue);
    expect(callbackCount, 1);
    expect(callbackAuthentication, same(authentication));
  });

  test('rejects a non-biometric authentication before invoking callback', () async {
    var callbackInvoked = false;

    await expectLater(
      sdk.groupedBiometricAuthentication(
        PowerAuthAuthentication.possession(),
        (_) async => callbackInvoked = true,
      ),
      throwsA(
        isA<PowerAuthException>().having(
          (error) => error.code,
          'code',
          PowerAuthErrorCode.wrongParameter,
        ),
      ),
    );
    expect(platform.resolveCount, 1);
    expect(callbackInvoked, isFalse);
  });

  test('does not resolve authentication for an unconfigured instance', () async {
    platform.configured = false;

    await expectLater(
      sdk.groupedBiometricAuthentication(
        PowerAuthAuthentication.biometry(
          biometricPrompt: PowerAuthBiometricPrompt(promptMessage: 'Authenticate'),
        ),
        (_) async {},
      ),
      throwsA(
        isA<PowerAuthException>().having(
          (error) => error.code,
          'code',
          PowerAuthErrorCode.instanceNotConfigured,
        ),
      ),
    );
    expect(platform.resolveCount, 0);
  });

  test('fails the group when its callback leaks an exception', () async {
    await expectLater(
      sdk.groupedBiometricAuthentication(
        PowerAuthAuthentication.biometry(
          biometricPrompt: PowerAuthBiometricPrompt(promptMessage: 'Authenticate'),
        ),
        (_) async => throw StateError('uncaught callback failure'),
      ),
      throwsA(
        isA<PowerAuthException>()
            .having(
              (error) => error.code,
              'code',
              PowerAuthErrorCode.unknownError,
            )
            .having(
              (error) => error.message,
              'message',
              contains('groupedAuthenticationCalls'),
            ),
      ),
    );
    expect(platform.resolveCount, 1);
  });
}
