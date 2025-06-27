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
import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/suites/test_suite.dart';

class PowerAuthSignatureTests extends TestSuiteWithActivation {

  @override
  List<Future<void> Function()> getTests() => [
    testSignatureCalculation,
    testWrongPassword,
    testDeviceSignedData,
    // testServerSignedData_WithNoActivation,
    // testServerSignedData_WithActivation
  ];

  @override
  Future<void> beforeEach() async {
    await super.beforeEach();
    await helper.prepareActiveActivation(await credentials.validPasswordObject());
  }

  Future<void> testSignatureCalculation() async {

    final activationId = await sdk.getActivationIdentifier();

    for (final td in _testData) {

      // Prepare auth object
      PowerAuthAuthentication auth;
      if (td.factors == SignatureType.possession) {
        auth = credentials.possession();
      } else if (td.factors == SignatureType.possessionKnowledge) {
        auth = await (td.shouldFail ? credentials.invalidKnowledge() : credentials.knowledge());
      } else {
        auth = credentials.biometry();
      }
      PowerAuthAuthorizationHttpHeader header;
      if (td.method == 'POST') {
        header = await sdk.requestSignature(auth, td.method, td.uriId, td.body);
      } else if (td.method == 'GET') {
        header = await sdk.requestGetSignature(auth, td.uriId, td.queryParams);
      } else {
        throw "Unsupported HTTP method ${td.method}";
      }

      // Let's validate signature on the server
      final parsed = SignatureHelper.parseHeader(header.value);
      await expect(parsed.activationId).toBe(activationId);
      // expect(parsed.applicationKey).toBe(this.helper.appSetup.appKey);
      await expect(SignatureType.fromString(parsed.signatureType.toUpperCase())).toBe(td.factors);

      final result = await helper.verifySignature(td.method, td.uriId, header.value, td.body ?? "");
      await expect(!td.shouldFail).toBe(result.signatureValid, message: "Signature verification failed for ${td.method} ${td.uriId} with body ${td.body}");
    }
  }

  Future<void> testWrongPassword() async {
    var status = await sdk.fetchActivationStatus();
    final maxFailCount = status.maxFailCount;
    for (var i = 1; i <= maxFailCount; i++) {
        await expect(status.state).toBe(PowerAuthActivationState.active);
        await expect(sdk.validatePassword(await credentials.invalidPasswordObject())).toThrow(PowerAuthErrorCode.authenticationError);
        status = await sdk.fetchActivationStatus();
        await expect(status.failCount).toBe(i);
        await expect(status.remainingAttempts).toBe(maxFailCount - i);
    }
    await expect(status.state).toBe(PowerAuthActivationState.blocked);
    await expect(status.remainingAttempts).toBe(0);
  }

  Future<void> testDeviceSignedData() async {
      final dataToSign = 'This is a very sensitive information and must be signed.';
      //final activationId = await sdk.getActivationIdentifier();
      await expect(sdk.signDataWithDevicePrivateKey(await credentials.knowledge(), dataToSign)).toSucceed();
      // Now verify signature on the server.
      // TODO: missing verification API
      //const result = await this.serverApi.verifyDeviceSignedData(activationId!, dataToSign, signature)
      //expect(result).toBe(true)
  }

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
  SignatureTestData(method: 'POST', uriId: '/some/uriId', body: 'Hello world', factors: SignatureType.possession),
  SignatureTestData(method: 'POST', uriId: '/some/uriId', body: null, factors: SignatureType.possession),
  SignatureTestData(method: 'POST', uriId: '/some/uriId/knowledge', body: '{ super value }', factors: SignatureType.possessionKnowledge),
  SignatureTestData(method: 'POST', uriId: '/some/uriId/knowledge', body: null, factors: SignatureType.possessionKnowledge),
  SignatureTestData(method: 'POST', uriId: '/failed/knowledge', body: null, factors: SignatureType.possessionKnowledge, shouldFail: true),
  SignatureTestData(method: 'POST', uriId: '/very/secure', body: '{}', factors: SignatureType.possessionKnowledge),
  // TODO: not ready for GET yet
  // SignatureTestData(method: 'GET', uriId: '/uri/ID', queryParams: {"param1": "valueX","something": "ExpectedValue"}, factors: SignatureType.possession),
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
    header
        .substring(SignatureHelper.signatureMagic.length)
        .split(', ')
        .forEach((keyValue) {
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
    });

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