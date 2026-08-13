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
  var algorithm = 'p384l3';
  var invalidPublicKeyType = false;

  setUp(() {
    calls.clear();
    platform = PowerAuthMethodChannel();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return switch (call.method) {
            'password_initialize' => 'password-id',
            'register_releaseNativeObject' => null,
            'getCurrentAlgorithm' => algorithm,
            'cleanupInstanceData' => null,
            'startProtocolUpgrade' => <String, dynamic>{
              'activationStatusFetchRequired': true,
              'activationFingerprint': null,
              'biometryFactorRemoved': false,
            },
            'calculateDigitalSignature' => Uint8List.fromList([1, 2, 3]),
            'verifyDigitalSignature' => null,
            'exportDevicePublicKeys' => <dynamic>[
              <String, dynamic>{
                'keyType': invalidPublicKeyType ? 'unknown' : 'ec',
                'keyAlgorithm': 'P-384',
                'keyData': Uint8List.fromList([4, 5, 6]),
              },
              if (!invalidPublicKeyType)
                <String, dynamic>{
                  'keyType': 'mlDsa',
                  'keyAlgorithm': 'ML-DSA-65',
                  'keyData': Uint8List.fromList([7, 8, 9]),
                },
            ],
            'calculateJwsSignature' => 'header.payload.signature',
            'verifyJwsSignature' => null,
            'createCertificateSigningRequest' => 'certificate-request',
            _ => throw StateError('Unexpected method ${call.method}'),
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'barrel exports public service types and string identity attributes',
    () {
      final sdk = PowerAuth('instance');
      final PowerAuthTimeSynchronizationService timeService =
          sdk.timeSynchronizationService;
      final PowerAuthExternalPendingOperation externalOperation =
          PowerAuthExternalPendingOperation.fromMap({
            'externalOperationType': 'protocolUpgrade',
            'externalApplicationId': 'other-app',
          });
      final activation = PowerAuthActivation.fromIdentityAttributes(
        identityAttributes: {'username': 'john.doe@example.com'},
        name: 'Test device',
      );

      expect(timeService, isA<PowerAuthTimeSynchronizationService>());
      expect(
        externalOperation.externalOperationType,
        PowerAuthExternalPendingOperationType.protocolUpgrade,
      );
      expect(activation.toMap()['identityAttributes'], {
        'username': 'john.doe@example.com',
      });
    },
  );

  test('maps every supported algorithm and rejects an unknown value', () async {
    for (final expected in PowerAuthAlgorithm.values) {
      algorithm = expected.name;
      expect(await platform.getCurrentAlgorithm('instance'), expected);
      final call = calls.removeLast();
      expect(call.method, 'getCurrentAlgorithm');
      expect(call.arguments, {'instanceId': 'instance'});
    }

    algorithm = 'future-algorithm';
    await expectLater(
      platform.getCurrentAlgorithm('instance'),
      throwsA(
        isA<PowerAuthException>().having(
          (error) => error.code,
          'code',
          PowerAuthErrorCode.unknownError,
        ),
      ),
    );
  });

  test('serializes cleanup configuration without dropping platform data', () async {
    final configuration = PowerAuthConfiguration(
      configuration: 'sdk-config',
      baseEndpointUrl: 'https://example.com',
      algorithm: PowerAuthAlgorithm.p384l5,
      offlineAuthenticationCodeComponentLength: 6,
    );
    final keychain = PowerAuthKeychainConfiguration(
      minimalRequiredKeychainProtection: PowerAuthKeychainProtection.hardware,
    );
    final sharing = PowerAuthSharingConfiguration(
      appGroup: 'group.test',
      appIdentifier: 'test-app',
      keychainAccessGroup: 'test-keychain',
    );

    await platform.cleanupInstanceData(
      instanceId: 'instance',
      configuration: configuration,
      keychainConfiguration: keychain,
      sharingConfiguration: sharing,
    );

    expect(calls.single.method, 'cleanupInstanceData');
    expect(calls.single.arguments, {
      'instanceId': 'instance',
      'configuration': configuration.toMap(),
      'keychainConfiguration': keychain.toMap(),
      'sharingConfiguration': sharing.toMap(),
    });
  });

  test('protocol upgrade sends biometry flag and decodes result', () async {
    final password = PowerAuthPassword();

    final result = await platform.startProtocolUpgrade(
      'instance',
      password,
      upgradeBiometry: true,
    );

    expect(result.activationStatusFetchRequired, isTrue);
    expect(result.activationFingerprint, isNull);
    expect(result.biometryFactorRemoved, isFalse);
    expect(calls.map((call) => call.method), [
      'password_initialize',
      'startProtocolUpgrade',
    ]);
    expect(calls.last.arguments, {
      'instanceId': 'instance',
      'password': {'objectId': 'password-id', 'destroyOnUse': true},
      'upgradeBiometry': true,
    });
  });

  test('signature APIs preserve binary data and all key identifiers', () async {
    final data = Uint8List.fromList([10, 20, 30]);
    final signature = Uint8List.fromList([40, 50, 60]);
    final authentication = PowerAuthAuthentication.possession();

    final calculated = await platform.calculateDigitalSignature(
      'instance',
      authentication,
      data,
      PowerAuthSignatureKeyId.deviceMlDsa,
    );
    data[0] = 99;
    expect(calculated, [1, 2, 3]);
    expect(calls.last.arguments, {
      'instanceId': 'instance',
      'data': Uint8List.fromList([10, 20, 30]),
      'signatureKeyId': 'deviceMlDsa',
      'authentication': {
        'isPersist': false,
        'isBiometry': false,
        'isReusable': false,
      },
    });

    await platform.verifyDigitalSignature(
      'instance',
      signature,
      Uint8List.fromList([1]),
      PowerAuthSignatureKeyId.server,
    );
    expect(calls.last.arguments, {
      'instanceId': 'instance',
      'signature': signature,
      'data': Uint8List.fromList([1]),
      'signatureKeyId': 'server',
    });

    final jws = await platform.calculateJwsSignature(
      'instance',
      authentication,
      Uint8List.fromList([7, 8]),
      'JWT',
      false,
      PowerAuthSignatureKeyId.device,
    );
    expect(jws, 'header.payload.signature');
    expect(calls.last.arguments, {
      'instanceId': 'instance',
      'data': Uint8List.fromList([7, 8]),
      'dataType': 'JWT',
      'compact': false,
      'signatureKeyId': 'device',
      'authentication': {
        'isPersist': false,
        'isBiometry': false,
        'isReusable': false,
      },
    });

    await platform.verifyJwsSignature(
      'instance',
      jws,
      false,
      true,
      PowerAuthSignatureKeyId.master,
    );
    expect(calls.last.arguments, {
      'instanceId': 'instance',
      'signature': jws,
      'compact': false,
      'strict': true,
      'signatureKeyId': 'master',
    });

    final csr = await platform.createCertificateSigningRequest(
      'instance',
      authentication,
      {'CN': 'Test', 'O': 'Wultra'},
      ['test.example.com'],
      PowerAuthSignatureKeyId.deviceEc,
    );
    expect(csr, 'certificate-request');
    expect(calls.last.arguments, {
      'instanceId': 'instance',
      'distinguishedNames': {'CN': 'Test', 'O': 'Wultra'},
      'subjectAltNames': ['test.example.com'],
      'signatureKeyId': 'deviceEc',
      'authentication': {
        'isPersist': false,
        'isBiometry': false,
        'isReusable': false,
      },
    });
  });

  test('public-key export decodes both key types and rejects new native types', () async {
    final keys = await platform.exportDevicePublicKeys(
      'instance',
      PowerAuthDevicePublicKeyFormat.der,
    );

    expect(keys, hasLength(2));
    expect(keys[0].keyType, PowerAuthSignatureKeyType.ec);
    expect(keys[0].keyAlgorithm, 'P-384');
    expect(keys[0].keyData, [4, 5, 6]);
    expect(keys[1].keyType, PowerAuthSignatureKeyType.mlDsa);
    expect(keys[1].keyAlgorithm, 'ML-DSA-65');
    expect(keys[1].keyData, [7, 8, 9]);
    expect(calls.single.arguments, {
      'instanceId': 'instance',
      'format': 'der',
    });

    calls.clear();
    invalidPublicKeyType = true;
    await expectLater(
      platform.exportDevicePublicKeys(
        'instance',
        PowerAuthDevicePublicKeyFormat.raw,
      ),
      throwsA(
        isA<PowerAuthException>().having(
          (error) => error.code,
          'code',
          PowerAuthErrorCode.unknownError,
        ),
      ),
    );
  });
}
