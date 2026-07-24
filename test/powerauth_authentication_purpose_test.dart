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
import 'package:flutter_powerauth_mobile_sdk_plugin/src/powerauth/powerauth_method_channel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('powerauth_plugin');
  final calls = <MethodCall>[];
  late PowerAuthMethodChannel platform;

  setUp(() {
    calls.clear();
    platform = PowerAuthMethodChannel();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'password_initialize') {
            return 'password-id';
          }
          final arguments = call.arguments as Map<dynamic, dynamic>?;
          final authentication =
              arguments?['authentication'] as Map<dynamic, dynamic>?;
          if (call.method == 'requestSignature' &&
              authentication?['isPersist'] == true) {
            throw PlatformException(code: 'wrongParameter');
          }
          if (call.method == 'persistActivation' &&
              authentication?['isPersist'] == false) {
            throw PlatformException(code: 'wrongParameter');
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('serializes isPersist for both authentication types', () async {
    final authenticationArgs = await PowerAuthAuthentication.possession()
        .prepareAuthArguments({});
    final persistArgs = await PowerAuthAuthentication.persistWithPassword(
      PowerAuthPassword(),
    ).prepareAuthArguments({});

    expect(
      authenticationArgs['authentication'],
      containsPair('isPersist', false),
    );
    expect(persistArgs['authentication'], containsPair('isPersist', true));
    expect(authenticationArgs['authentication'], isNot(contains('purpose')));
    expect(persistArgs['authentication'], isNot(contains('purpose')));
  });

  test('rejects persistence authentication in a signing operation', () async {
    final authentication = PowerAuthAuthentication.persistWithPassword(
      PowerAuthPassword(),
    );

    await expectLater(
      platform.authenticationHeaderForRequestWithBody(
        'instance',
        authentication,
        'POST',
        '/operation',
      ),
      throwsA(
        isA<PowerAuthException>().having(
          (error) => error.code,
          'code',
          PowerAuthErrorCode.wrongParameter,
        ),
      ),
    );
    expect(calls.map((call) => call.method), [
      'password_initialize',
      'authenticationHeaderForRequestWithBody',
    ]);
    expect(
      (calls.last.arguments as Map)['authentication'],
      containsPair('isPersist', true),
    );
  });

  test('rejects normal authentication when persisting activation', () async {
    final authentication = PowerAuthAuthentication.password(
      PowerAuthPassword(),
    );

    await expectLater(
      platform.persistActivation('instance', authentication),
      throwsA(
        isA<PowerAuthException>().having(
          (error) => error.code,
          'code',
          PowerAuthErrorCode.wrongParameter,
        ),
      ),
    );
    expect(calls.map((call) => call.method), [
      'password_initialize',
      'persistActivation',
    ]);
    expect(
      (calls.last.arguments as Map)['authentication'],
      containsPair('isPersist', false),
    );
  });

  test(
    'does not prompt or downgrade persistence biometry during signing',
    () async {
      final authentication =
          PowerAuthAuthentication.persistWithPasswordAndBiometry(
            password: PowerAuthPassword(),
            biometricPrompt: PowerAuthBiometricPrompt(
              promptMessage: 'Authenticate',
              promptTitle: 'Signing',
            ),
          );

      await expectLater(
        platform.authenticationHeaderForRequestWithBody(
          'instance',
          authentication,
          'POST',
          '/operation',
        ),
        throwsA(
          isA<PowerAuthException>().having(
            (error) => error.code,
            'code',
            PowerAuthErrorCode.wrongParameter,
          ),
        ),
      );
      expect(calls.map((call) => call.method), [
        'password_initialize',
        'authenticationHeaderForRequestWithBody',
      ]);
      expect(
        calls.map((call) => call.method),
        isNot(contains('authenticateWithBiometry')),
      );
    },
  );

  test(
    'does not forward biometric authentication without a native key',
    () async {
      final authentication = PowerAuthAuthentication.biometry(
        biometricPrompt: PowerAuthBiometricPrompt(
          promptMessage: 'Authenticate',
          promptTitle: 'Signing',
        ),
      );

      await expectLater(
        platform.authenticationHeaderForRequestWithBody(
          'instance',
          authentication,
          'POST',
          '/operation',
        ),
        throwsA(
          isA<PowerAuthException>().having(
            (error) => error.code,
            'code',   
            PowerAuthErrorCode.invalidNativeObject,
          ),
        ),
      );
      expect(calls.map((call) => call.method), ['authenticationHeaderForRequestWithBody']);
    },
  );
}
