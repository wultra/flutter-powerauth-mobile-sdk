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

import 'dart:async';

import '../model/base_native_object.dart';
import '../model/base_releasable_object.dart';
import '../model/powerauth_data_format.dart';
import '../model/powerauth_encryption_http_header.dart';

/// Scope of encryptor.
enum PowerAuthEncryptorScope {

  /// Application scope - encryption is available without activation.
  application,

  /// Activation scope - encryption requires valid activation.
  activation,
}

/// Class representing encrypted data in request or response.
class PowerAuthCryptogram {

  /// Temporary key identifier.
  final String? temporaryKeyId;

  /// Ephemeral public key, valid only for encrypted request.
  final String? ephemeralPublicKey;

  /// Encrypted data, valid for request and response.
  final String encryptedData;

  /// Message authenticated code, valid for request and response.
  final String mac;

  /// Nonce, valid for encrypted request.
  final String? nonce;

  /// Timestamp of request or response in milliseconds since 1.1.1970.
  final int timestamp;

  PowerAuthCryptogram({
    required this.temporaryKeyId,
    this.ephemeralPublicKey,
    required this.encryptedData,
    required this.mac,
    this.nonce,
    required this.timestamp,
  });

  /// Creates a [PowerAuthCryptogram] from a map.
  factory PowerAuthCryptogram.fromMap(Map<dynamic, dynamic> map) {
    return PowerAuthCryptogram(
      temporaryKeyId: map['temporaryKeyId'] as String?,
      ephemeralPublicKey: map['ephemeralPublicKey'] as String?,
      encryptedData: map['encryptedData'] as String,
      mac: map['mac'] as String,
      nonce: map['nonce'] as String?,
      timestamp: map['timestamp'] as int,
    );
  }

  /// Converts this [PowerAuthCryptogram] to a map.
  Map<String, dynamic> toMap() {
    return {
      'temporaryKeyId': temporaryKeyId,
      'ephemeralPublicKey': ephemeralPublicKey,
      'encryptedData': encryptedData,
      'mac': mac,
      'nonce': nonce,
      'timestamp': timestamp,
    }..removeWhere((key, value) => value == null);
  }
}

/// Object returned from the `encryptRequest()` function.
class PowerAuthEncryptedRequestData {

  /// Cryptogram with encrypted request data.
  final PowerAuthCryptogram cryptogram;

  /// HTTP request header. You must include this header to your HTTP request
  /// to properly decrypt the request data on the server.
  ///
  /// If you plan to combine encryption with PowerAuth Symmetric Signature, then
  /// the header can be omitted.
  final PowerAuthEncryptionHttpHeader header;

  /// Object that can decrypt encrypted response received from the server.
  final PowerAuthDecryptor decryptor;

  PowerAuthEncryptedRequestData({
    required this.cryptogram,
    required this.header,
    required this.decryptor,
  });
}

/// An abstract base class that implements End-To-End encryption. Use [PowerAuth] class to get instance
/// of encryptor.
abstract class PowerAuthEncryptor extends BaseNativeObject {

  /// Scope of this encryptor.
  PowerAuthEncryptorScope get encryptorScope;

  /// Determine whether encryptor can encrypt the request.
  ///
  /// The encryptor is reusable, so this method typically returns `true`, unless the parent
  /// `PowerAuth` instance is deconfigured or has no longer valid activation (if activation scoped).
  Future<bool> canEncryptRequest();

  /// Encrypt the request data.
  ///
  /// [body] is the data to encrypt. By default plain string is expected, but you can use [bodyFormat]
  /// parameter to specify Base64 encoded string at input.
  ///
  /// [bodyFormat] specifies encoding of [body] parameter. The default value is [PowerAuthDataFormat.utf8],
  /// so plain string is expected in [body] parameter.
  ///
  /// Returns object containing encrypted data, HTTP header and decryptor for the response decryption.
  Future<PowerAuthEncryptedRequestData> encryptRequest(
    String body, [
    PowerAuthDataFormat bodyFormat = PowerAuthDataFormat.utf8,
  ]);
}

/// An abstract base class defining a decryptor that is capable to decrypt encrypted response received from the server.
///
/// Be aware that the native underlying object has a limited lifetime set to 5 minutes. If you don't decrypt
/// the response within this time interval, then the information required for the request decryption is lost.
abstract class PowerAuthDecryptor extends BaseReleasableObject {

  /// Scope of this decryptor.
  PowerAuthEncryptorScope get decryptorScope;

  /// Determine whether object is able to decrypt the response.
  Future<bool> canDecryptResponse();

  /// Decrypt the response received from the server. The underlying native object is automatically released
  /// after this call.
  ///
  /// [cryptogram] contains encrypted response from the server.
  ///
  /// [outputDataFormat] specifies data format expected at the output. If not used, then [PowerAuthDataFormat.utf8] is applied.
  ///
  /// Returns decrypted data in specified format.
  Future<String> decryptResponse(
    PowerAuthCryptogram cryptogram, [
    PowerAuthDataFormat outputDataFormat = PowerAuthDataFormat.utf8,
  ]);
}
