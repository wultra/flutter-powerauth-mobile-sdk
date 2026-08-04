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

import 'dart:convert';

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';

import '../utils/activation_credentials.dart';
import '../utils/helper_functions.dart';
import '../utils/integration_helper.dart';
import '../utils/native_test.dart';
import '../utils/object_cleanup_helper.dart';

void main() {
  group('Advanced signature tests', () {
    late IntegrationHelper helper;
    late ObjectCleanupHelper cleanupHelper;
    late PowerAuth sdk;
    late ActivationCredentials credentials;

    setUp(() async {
      cleanupHelper = ObjectCleanupHelper();
      sdk = PowerAuth(IntegrationHelper.randomString(30));
      helper = IntegrationHelper(sdk);
      await helper.configure();
      credentials = ActivationCredentials();
      await helper.prepareActiveActivation(
        await credentials.validPasswordObject(),
      );
    });

    tearDown(() async {
      await helper.cleanup();
      await cleanupHelper.dispose();
    });

    test('exports the complete device key set in both formats', () async {
      final algorithm = await sdk.currentAlgorithm;
      final der = await sdk.exportDevicePublicKeys(
        PowerAuthDevicePublicKeyFormat.der,
      );
      final raw = await sdk.exportDevicePublicKeys(
        PowerAuthDevicePublicKeyFormat.raw,
      );
      final expectedTypes = switch (algorithm) {
        PowerAuthAlgorithm.p384l3 || PowerAuthAlgorithm.p384l5 => {
          PowerAuthSignatureKeyType.ec,
          PowerAuthSignatureKeyType.mlDsa,
        },
        _ => {PowerAuthSignatureKeyType.ec},
      };

      expect(der, hasLength(expectedTypes.length));
      expect(raw, hasLength(expectedTypes.length));
      expect(der.map((key) => key.keyType).toSet(), expectedTypes);
      expect(raw.map((key) => key.keyType).toSet(), expectedTypes);
      for (final type in expectedTypes) {
        final derKey = der.singleWhere((key) => key.keyType == type);
        final rawKey = raw.singleWhere((key) => key.keyType == type);
        expect(derKey.keyAlgorithm, rawKey.keyAlgorithm);
        expect(derKey.keyAlgorithm, isNotEmpty);
        expect(derKey.keyData, isNotEmpty);
        expect(rawKey.keyData, isNotEmpty);
        expect(derKey.keyData, isNot(rawKey.keyData));
      }
    });

    test('round-trips compact and JSON JWS and rejects tampering', () async {
      final password = await credentials.validPasswordObject(destroyOnUse: false);
      cleanupHelper.cleanup.add(password);
      final authentication = PowerAuthAuthentication.password(password);
      final data = utf8Bytes('signed payload');

      final compact = await sdk.calculateJwsSignature(
        authentication,
        data,
        'JWT',
        true,
        PowerAuthSignatureKeyId.deviceEc,
      );
      final components = compact.split('.');
      expect(components, hasLength(3));
      final header = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(components[0]))),
      ) as Map<String, dynamic>;
      expect(header['typ'], 'JWT');
      expect(
        base64Url.decode(base64Url.normalize(components[1])),
        data,
      );
      await expectLater(
        sdk.verifyJwsSignature(
          compact,
          true,
          true,
          PowerAuthSignatureKeyId.deviceEc,
        ),
        completes,
      );

      final tamperedPayload = base64Url
          .encode(utf8Bytes('tampered payload'))
          .replaceAll('=', '');
      final tampered = '${components[0]}.$tamperedPayload.${components[2]}';
      await expectLater(
        sdk.verifyJwsSignature(
          tampered,
          true,
          true,
          PowerAuthSignatureKeyId.deviceEc,
        ),
        throwsPowerAuthCode(PowerAuthErrorCode.wrongSignature),
      );

      final json = await sdk.calculateJwsSignature(
        authentication,
        data,
        'application/powerauth-test',
        false,
        PowerAuthSignatureKeyId.device,
      );
      expect(jsonDecode(json), isA<Map<String, dynamic>>());
      await expectLater(
        sdk.verifyJwsSignature(
          json,
          false,
          true,
          PowerAuthSignatureKeyId.device,
        ),
        completes,
      );
    });

    test('creates a structurally valid PKCS10 request', () async {
      final password = await credentials.validPasswordObject();
      cleanupHelper.cleanup.add(password);
      final csr = await sdk.createCertificateSigningRequest(
        PowerAuthAuthentication.password(password),
        {'CN': 'PowerAuth Integration Test', 'O': 'Wultra'},
        ['DNS: test.example.com', 'DNS: test2.example.com'],
        PowerAuthSignatureKeyId.deviceEc,
      );
      final lines = csr.trim().split('\n');

      expect(lines.first, '-----BEGIN CERTIFICATE REQUEST-----');
      expect(lines.last, '-----END CERTIFICATE REQUEST-----');
      final der = base64Decode(lines.sublist(1, lines.length - 1).join());
      expect(der.length, greaterThan(256));
      expect(der.first, 0x30);
    });
  });
}
