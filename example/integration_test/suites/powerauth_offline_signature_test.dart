/*
 * Copyright 2026 Wultra s.r.o.
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

import '../utils/native_test.dart';

/// URI ID that PowerAuth Cloud uses when it verifies offline operation OTPs.
const _offlineAuthorizeUriId = '/operation/authorize/offline';

main() {
  group('Offline signature tests', () {
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

    test('testOfflineSignatureApprovesOperation', () async {
      final operation = await helper.createOperation();
      final qrCode = await helper.getOperationQrCode(operation.operationId);
      final qrOperation = _OfflineQrOperation.parse(qrCode.operationQrCodeData);
      expect(qrOperation.operationId, operation.operationId);
      expect(qrOperation.nonce, qrCode.nonce);

      final otp = await sdk.offlineSignature(
        await credentials.knowledge(),
        _offlineAuthorizeUriId,
        qrOperation.nonce,
        qrOperation.dataForOfflineSigning(),
      );
      expect(otp, matches(RegExp(r'^[0-9]{8}-[0-9]{8}$')));

      final result = await helper.verifyOfflineOtp(
        operation.operationId,
        otp,
        qrCode.nonce,
      );
      expect(result.otpValid, isTrue);
      expect(result.userId, helper.userId);
      expect(result.registrationId, await sdk.getActivationIdentifier());
      expect(result.authenticationCodeType, 'POSSESSION_KNOWLEDGE');

      final approved = await helper.getOperation(operation.operationId);
      expect(approved.status, 'APPROVED');
    });

    test('testOfflineSignatureWithInvalidPasswordIsRejected', () async {
      final operation = await helper.createOperation();
      final qrCode = await helper.getOperationQrCode(operation.operationId);
      final qrOperation = _OfflineQrOperation.parse(qrCode.operationQrCodeData);

      // The offline code is computed locally, so a wrong password still yields an OTP.
      final otp = await sdk.offlineSignature(
        await credentials.invalidKnowledge(),
        _offlineAuthorizeUriId,
        qrOperation.nonce,
        qrOperation.dataForOfflineSigning(),
      );
      expect(otp, matches(RegExp(r'^[0-9]{8}-[0-9]{8}$')));

      final result = await helper.verifyOfflineOtp(
        operation.operationId,
        otp,
        qrCode.nonce,
      );
      expect(
        result.otpValid,
        isFalse,
        reason: 'OTP computed with an invalid password must be rejected',
      );

      final pending = await helper.getOperation(operation.operationId);
      expect(pending.status, 'PENDING');
    });
  });
}

/// Minimal parser of the offline operation QR code produced by PowerAuth Cloud.
///
/// Format (lines separated by `\n`):
/// `operationId`, `title`, `message`, `operationData`, `flags`, optional
/// `totp` and other attributes, `nonce`, `signature`.
class _OfflineQrOperation {
  static const _minimumAttributes = 7;

  final String operationId;
  final String operationData;
  final String? totp;
  final String nonce;

  _OfflineQrOperation({
    required this.operationId,
    required this.operationData,
    required this.totp,
    required this.nonce,
  });

  factory _OfflineQrOperation.parse(String qrCodeData) {
    final attributes = qrCodeData.split('\n');
    if (attributes.length < _minimumAttributes) {
      throw FormatException(
        'QR operation needs at least $_minimumAttributes attributes, '
        'got ${attributes.length}',
        qrCodeData,
      );
    }
    return _OfflineQrOperation(
      operationId: attributes[0],
      operationData: attributes[3],
      totp: attributes.length > _minimumAttributes ? attributes[5] : null,
      nonce: attributes[attributes.length - 2],
    );
  }

  /// Data signed by the mobile token, see `QROperation.dataForOfflineSigning`
  /// in the Wultra Mobile Token SDK.
  Uint8List dataForOfflineSigning() => utf8Bytes(
    totp == null
        ? '$operationId&$operationData'
        : '$operationId&$operationData&$totp',
  );
}
