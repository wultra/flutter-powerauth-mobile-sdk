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

import '../model/powerauth_encryptor.dart';
import '../model/powerauth_http_header.dart';
import 'powerauth_encryptor_platform_interface.dart';

/// Platform-backed implementation of [PowerAuthEncryptor].
///
/// This class is internal to the package. Applications acquire an encryptor
/// from `PowerAuth`.
class PowerAuthEncryptorImpl implements PowerAuthEncryptor {
  static PowerAuthEncryptorPlatform get _platform =>
      PowerAuthEncryptorPlatform.instance;

  @override
  final PowerAuthEncryptorScope scope;

  final String _objectId;

  PowerAuthEncryptorImpl._({required this.scope, required this._objectId});

  /// Acquires and registers one native encryptor.
  static Future<PowerAuthEncryptor> acquire({
    required PowerAuthEncryptorScope scope,
    required String powerAuthInstanceId,
  }) async {
    final objectId = await _platform.initialize(
      scope: scope,
      powerAuthInstanceId: powerAuthInstanceId,
    );
    return PowerAuthEncryptorImpl._(scope: scope, objectId: objectId);
  }

  @override
  Future<bool> canEncryptRequest() {
    return _platform.canEncryptRequest(_objectId);
  }

  @override
  Future<bool> canDecryptResponse() {
    return _platform.canDecryptResponse(_objectId);
  }

  @override
  Future<PowerAuthEncryptedRequest> encryptRequest(
    Uint8List? requestBody,
  ) async {
    final result = await _platform.encryptRequest(_objectId, requestBody);
    final headers = (result['requestHeaders'] as List<dynamic>)
        .map((header) => PowerAuthHttpHeader.fromMap(header as Map))
        .toList(growable: false);
    return PowerAuthEncryptedRequest(
      requestBody: result['requestBody'] as Uint8List,
      requestHeaders: headers,
    );
  }

  @override
  Future<Uint8List> decryptResponse(Uint8List responseBody) {
    return _platform.decryptResponse(_objectId, responseBody);
  }

  @override
  Future<void> release() {
    return _platform.release(_objectId);
  }
}
