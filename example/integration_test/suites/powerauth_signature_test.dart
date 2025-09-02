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

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import '../utils/activation_credentials.dart';
import '../utils/integration_helper.dart';

import 'package:flutter_test/flutter_test.dart';

main() {
  group('Signature tests', () {
    late IntegrationHelper helper;
    late PowerAuth sdk;
    late ActivationCredentials credentials;

    setUp(() async {
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
        PowerAuthAuthorizationHttpHeader header;
        if (td.method == 'POST') {
          header = await sdk.requestSignature(
            auth,
            td.method,
            td.uriId,
            td.body,
          );
        } else if (td.method == 'GET') {
          header = await sdk.requestGetSignature(
            auth,
            td.uriId,
            td.queryParams,
          );
        } else {
          throw "Unsupported HTTP method ${td.method}";
        }

        // Let's validate signature on the server
        final parsed = SignatureHelper.parseHeader(header.value);
        expect(parsed.activationId, activationId);
        expect(
          SignatureType.fromString(parsed.signatureType.toUpperCase()),
          td.factors,
        );

        final result = await helper.verifySignature(
          td.method,
          td.uriId,
          header.value,
          td.body ?? "",
        );
        expect(
          !td.shouldFail,
          result.signatureValid,
          reason:
              "Signature verification failed for ${td.method} ${td.uriId} with body ${td.body}",
        );
      }
    });

    test('testWrongPassword', () async {
      var status = await sdk.fetchActivationStatus();
      final maxFailCount = status.maxFailCount;
      for (var i = 1; i <= maxFailCount; i++) {
        expect(status.state, PowerAuthActivationState.active);
        await expectLater(
          sdk.validatePassword(await credentials.invalidPasswordObject()),
          throwsA(
            isA<PowerAuthException>().having(
              (e) => e.code,
              "code",
              PowerAuthErrorCode.authenticationError,
            ),
          ),
        );
        status = await sdk.fetchActivationStatus();
        expect(status.failCount, i);
        expect(status.remainingAttempts, maxFailCount - i);
      }
      expect(status.state, PowerAuthActivationState.blocked);
      expect(status.remainingAttempts, 0);
    });

    test('testDeviceSignedData', () async {
      final dataToSign =
          'This is a very sensitive information and must be signed.';
      await expectLater(
        sdk.signDataWithDevicePrivateKey(
          await credentials.knowledge(),
          dataToSign,
        ),
        completes,
      );
      // Now verify signature on the server.
      // TODO: missing verification API
      //const result = await this.serverApi.verifyDeviceSignedData(activationId!, dataToSign, signature)
      //expect(result).toBe(true)
    });

    // async testServerSignedData_WithNoActivation() {
    //     const dataToSign = 'All your money are belong to us!'
    //     let signedPayload = await this.serverApi.createNonPersonalizedOfflineSignature(this.helper.application, dataToSign)
    //     let signedData = signedPayload.parsedSignedData
    //     let signature = signedPayload.parsedSignature
    //     expect(signedPayload.parsedData).toBe(dataToSign)
    //     expect(signedData).toBeNotNullish()
    //     expect(signature).toBeNotNullish()

    //     let result = await this.sdk.verifyServerSignedData(signedData!, signature!, true)
    //     expect(result).toBe(true)
    //     result = await this.sdk.verifyServerSignedData(Base64.encode(`A${signedData!}`), signature!, true)
    //     expect(result).toBe(false)
    // }

    // async testServerSignedData_WithActivation() {
    //     const activationId = await this.sdk.getActivationIdentifier()
    //     const dataToSign = 'All your money are belong to us!'
    //     let signedPayload = await this.serverApi.createPersonalizedOfflineSignature(activationId!, dataToSign)
    //     let signedData = signedPayload.parsedSignedData
    //     let signature = signedPayload.parsedSignature
    //     expect(signedPayload.parsedData).toBe(dataToSign)
    //     expect(signedData).toBeNotNullish()
    //     expect(signature).toBeNotNullish()

    //     let result = await this.sdk.verifyServerSignedData(signedData!, signature!, false)
    //     expect(result).toBe(true)
    //     result = await this.sdk.verifyServerSignedData(Base64.encode(`A${signedData!}`), signature!, false)
    //     expect(result).toBe(false)
    // }
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
    final signatureType = components['pa_signature_type'];
    final signature = components['pa_signature'];

    if (version == null) throw Exception('Missing pa_version in PA signature');
    if (activationId == null) throw Exception('Missing pa_activation_id in PA signature');
    if (nonce == null) throw Exception('Missing pa_nonce in PA signature');
    if (signatureType == null) throw Exception('Missing pa_signature_type in PA signature');
    if (signature == null) throw Exception('Missing pa_signature in PA signature');

    return OnlineSignature(
      signature: signature,
      activationId: activationId,
      nonce: nonce,
      signatureType: signatureType.toUpperCase(),
      signatureVersion: version,
    );
  }
}
