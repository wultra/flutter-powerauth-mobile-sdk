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

import 'powerauth_http_header.dart';

/// Scope of an end-to-end encryptor.
enum PowerAuthEncryptorScope {
  /// Application scope is available without an activation.
  application,

  /// Activation scope requires a valid activation when the encryptor is acquired.
  activation,
}

/// Encrypted request body and HTTP headers produced by [PowerAuthEncryptor].
class PowerAuthEncryptedRequest {
  /// Raw encrypted request body.
  final Uint8List requestBody;

  /// HTTP headers that must accompany [requestBody].
  final List<PowerAuthHttpHeader> requestHeaders;

  PowerAuthEncryptedRequest({
    required this.requestBody,
    required this.requestHeaders,
  });
}

/// A stateful, single-use end-to-end encryptor.
///
/// The same instance must encrypt one request and decrypt its response. Acquire
/// a new instance for every additional HTTP exchange. Always call [release]
/// when the exchange finishes, preferably from a `finally` block.
abstract class PowerAuthEncryptor {
  /// Scope used to acquire this encryptor.
  PowerAuthEncryptorScope get scope;

  /// Returns whether this instance can encrypt a request.
  Future<bool> canEncryptRequest();

  /// Returns whether this instance can decrypt a response.
  Future<bool> canDecryptResponse();

  /// Encrypts the supplied raw request bytes.
  Future<PowerAuthEncryptedRequest> encryptRequest(Uint8List? requestBody);

  /// Decrypts the raw encrypted HTTP response body.
  Future<Uint8List> decryptResponse(Uint8List responseBody);

  /// Releases the native encryptor.
  ///
  /// Always call this method when the exchange finishes, including after an
  /// error. Calling this method repeatedly is safe.
  Future<void> release();
}
