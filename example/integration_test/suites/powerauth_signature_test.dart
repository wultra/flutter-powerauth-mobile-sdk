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

import 'dart:typed_data';

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import '../utils/activation_credentials.dart';
import '../utils/helper_functions.dart';
import '../utils/integration_helper.dart';
import '../utils/object_cleanup_helper.dart';

import '../utils/native_test.dart';

main() {
  group('Signature tests', () {
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

    test('testSignatureCalculation', () async {
      final activationId = await sdk.getActivationIdentifier();
      for (final td in _testData) {
        // Prepare auth object
        PowerAuthAuthentication auth;
        if (td.factors == SignatureType.possession) {
          auth = credentials.possession();
        } else if (td.factors == SignatureType.possessionKnowledge) {
          auth =
              await (td.shouldFail
                  ? credentials.invalidKnowledge()
                  : credentials.knowledge());
        } else {
          auth = credentials.biometry();
        }
        PowerAuthHttpHeader header;
        if (td.method == 'POST') {
          header = await sdk.authenticationHeaderForRequestWithBody(
            auth,
            td.method,
            td.uriId,
            td.body == null ? null : utf8Bytes(td.body!),
          );
        } else if (td.method == 'GET') {
          header = await sdk.authenticationHeaderForRequestWithParams(
            auth,
            td.method,
            td.uriId,
            td.queryParams,
          );
        } else {
          throw "Unsupported HTTP method ${td.method}";
        }

        // Let's validate signature on the server
        final parsed = SignatureHelper.parseHeader(header.value);
        expect(header.name, 'X-PowerAuth-Authorization');
        expect(parsed.activationId, activationId);
        expect(
          SignatureType.fromString(parsed.signatureType.toUpperCase()),
          td.factors,
        );

        final result = await helper.verifySignature(
          td.method,
          td.uriId,
          header.value,
          td.body ?? '',
          queryParams: td.queryParams,
        );
        expect(
          result.signatureValid,
          !td.shouldFail,
          reason:
              "Signature verification failed for ${td.method} ${td.uriId} with body ${td.body}",
        );
      }
    });

    test('testDeviceDigitalSignatureRoundTripAndTampering', () async {
      final password = await credentials.validPasswordObject(
        destroyOnUse: false,
      );
      cleanupHelper.cleanup.add(password);
      final authentication = PowerAuthAuthentication.password(password);
      final data = utf8Bytes(
        'This is sensitive information and must be signed.',
      );
      final signature = await sdk.calculateDigitalSignature(
        authentication,
        data,
        PowerAuthSignatureKeyId.deviceEc,
      );
      expect(signature, isNotEmpty);
      await expectLater(
        sdk.verifyDigitalSignature(
          signature,
          data,
          PowerAuthSignatureKeyId.deviceEc,
        ),
        completes,
      );

      final tamperedData = utf8Bytes(
        'This is sensitive information and must be signed!',
      );
      await expectLater(
        sdk.verifyDigitalSignature(
          signature,
          tamperedData,
          PowerAuthSignatureKeyId.deviceEc,
        ),
        throwsPowerAuthCode(PowerAuthErrorCode.wrongSignature),
      );

      final tamperedSignature = signature.toList(growable: false);
      tamperedSignature[0] ^= 0x01;
      await expectLater(
        sdk.verifyDigitalSignature(
          Uint8List.fromList(tamperedSignature),
          data,
          PowerAuthSignatureKeyId.deviceEc,
        ),
        throwsPowerAuthCode(PowerAuthErrorCode.wrongSignature),
      );
    });
  });
}

enum SignatureType {
  possession,
  possessionKnowledge;

  static SignatureType fromString(String str) {
    switch (str) {
      case 'POSSESSION':
        return possession;
      case 'POSSESSION_KNOWLEDGE':
        return possessionKnowledge;
      default:
        throw Exception('Unknown signature type: $str');
    }
  }
}

class SignatureTestData {
  final String method;
  final String uriId;
  final String? body; // Can be String, Map<String, String>, or null
  final Map<String, String>? queryParams; // Can be null
  final SignatureType factors;
  final bool shouldFail;

  SignatureTestData({
    required this.method,
    required this.uriId,
    this.body,
    this.queryParams,
    required this.factors,
    this.shouldFail = false,
  });
}

final List<SignatureTestData> _testData = [
  SignatureTestData(
    method: 'POST',
    uriId: '/some/uriId',
    body: 'Hello world',
    factors: SignatureType.possession,
  ),
  SignatureTestData(
    method: 'GET',
    uriId: '/some/uriId',
    factors: SignatureType.possession,
  ),
  SignatureTestData(
    method: 'GET',
    uriId: '/some/uriId/params',
    queryParams: {'message': 'Hello world', 'page': '1'},
    factors: SignatureType.possession,
  ),
  SignatureTestData(
    method: 'POST',
    uriId: '/some/uriId',
    body: null,
    factors: SignatureType.possession,
  ),
  SignatureTestData(
    method: 'POST',
    uriId: '/some/uriId/knowledge',
    body: '{ super value }',
    factors: SignatureType.possessionKnowledge,
  ),
  SignatureTestData(
    method: 'POST',
    uriId: '/some/uriId/knowledge',
    body: null,
    factors: SignatureType.possessionKnowledge,
  ),
  SignatureTestData(
    method: 'POST',
    uriId: '/failed/knowledge',
    body: null,
    factors: SignatureType.possessionKnowledge,
    shouldFail: true,
  ),
  SignatureTestData(
    method: 'POST',
    uriId: '/very/secure',
    body: '{}',
    factors: SignatureType.possessionKnowledge,
  ),
];

class OnlineSignature {
  final String signature;
  final String activationId;
  final String nonce;
  final String signatureType;
  final String signatureVersion;

  OnlineSignature({
    required this.signature,
    required this.activationId,
    required this.nonce,
    required this.signatureType,
    required this.signatureVersion,
  });
}

class SignatureHelper {
  static const String signatureMagic = 'PowerAuth ';

  /// Parse authentication header produced in mobile SDK.
  /// [header] HTTP header's value.
  /// Returns object representing an online signature.
  static OnlineSignature parseHeader(String header) {
    if (!header.startsWith(SignatureHelper.signatureMagic)) {
      throw Exception('Signature string must begin with PowerAuth');
    }

    final Map<String, String> components = {};
    header.substring(SignatureHelper.signatureMagic.length).split(', ').forEach(
      (keyValue) {
        final equalIdx = keyValue.indexOf('=');
        if (equalIdx == -1) {
          throw Exception('Unknown component in header: $keyValue');
        }
        final key = keyValue.substring(0, equalIdx);
        var value = keyValue.substring(equalIdx + 1);
        if (!value.startsWith('"') || !value.endsWith('"')) {
          throw Exception('Value is not closed in parenthesis: $keyValue');
        }
        components[key] = value.substring(1, value.length - 1);
      },
    );

    final version = components['pa_version'];
    final activationId = components['pa_activation_id'];
    final nonce = components['pa_nonce'];
    final signatureType =
        components['pa_auth_code_type'] ??
        components['pa_signature_factors'] ??
        components['pa_signature_type'];
    final signature = components['pa_auth_code'] ?? components['pa_signature'];

    if (version == null) {
      throw Exception('Missing pa_version in PA signature');
    }
    if (activationId == null) {
      throw Exception('Missing pa_activation_id in PA signature');
    }
    if (nonce == null) {
      throw Exception('Missing pa_nonce in PA signature');
    }
    if (signatureType == null) {
      throw Exception('Missing signature factors in PA signature: $components');
    }
    if (signature == null) {
      throw Exception('Missing authentication code in PA signature');
    }

    return OnlineSignature(
      signature: signature,
      activationId: activationId,
      nonce: nonce,
      signatureType: signatureType.toUpperCase(),
      signatureVersion: version,
    );
  }
}
