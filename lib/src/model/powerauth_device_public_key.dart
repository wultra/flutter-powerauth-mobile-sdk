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

import 'powerauth_error.dart';
import 'powerauth_signature_key_id.dart';

/// Output format used when exporting device public keys.
enum PowerAuthDevicePublicKeyFormat {
  /// DER-encoded SubjectPublicKeyInfo structure.
  der,

  /// Raw key representation specific to the key algorithm.
  raw,
}

/// Exported device public key data.
class PowerAuthDevicePublicKeyData {
  /// Cryptographic type of the key.
  final PowerAuthSignatureKeyType keyType;

  /// Key algorithm name, such as `P-384` or `ML-DSA-65`.
  final String keyAlgorithm;

  /// Encoded public key bytes in the requested export format.
  final Uint8List keyData;

  /// Creates exported device public key data.
  PowerAuthDevicePublicKeyData({
    required this.keyType,
    required this.keyAlgorithm,
    required this.keyData,
  });

  /// Creates exported device public key data from platform channel data.
  factory PowerAuthDevicePublicKeyData.fromMap(Map<dynamic, dynamic> map) {
    final keyType = switch (map['keyType']) {
      'ec' => PowerAuthSignatureKeyType.ec,
      'mlDsa' => PowerAuthSignatureKeyType.mlDsa,
      final value => throw PowerAuthException(
        code: PowerAuthErrorCode.unknownError,
        message: 'Unknown signature key type received from native platform: \'$value\'.',
      ),
    };
    return PowerAuthDevicePublicKeyData(
      keyType: keyType,
      keyAlgorithm: map['keyAlgorithm'] as String,
      keyData: map['keyData'] as Uint8List,
    );
  }
}
