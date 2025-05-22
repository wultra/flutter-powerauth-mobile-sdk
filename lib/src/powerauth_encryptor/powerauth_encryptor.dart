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

import 'package:meta/meta.dart';

import '../model/base_native_object.dart';
import '../model/base_releasable_object.dart';
import '../model/powerauth_data_format.dart';
import '../model/powerauth_encryptor.dart';
import '../model/powerauth_encryption_http_header.dart';
import 'powerauth_encryptor_platform_interface.dart';

/// Implementation of [PowerAuthEncryptor] that uses the platform interface.
class PowerAuthRequestEncryptor extends BaseNativeObject
    implements PowerAuthEncryptor {

  static PowerAuthEncryptorPlatform get _platform =>
      PowerAuthEncryptorPlatform.instance;

  /// Scope of this encryptor.
  @override
  final PowerAuthEncryptorScope encryptorScope;

  /// Instance identifier of PowerAuth instance owning this encryptor.
  final String powerAuthInstanceId;

  /// Autorelease time in ms.
  final int? autoReleaseTimeMillis;

  /// Creates a new instance of [PowerAuthRequestEncryptor].
  ///
  /// [scope] is the scope of the encryptor.
  /// [powerAuthInstanceId] is the instance identifier of PowerAuth class owning this encryptor.
  /// [autoReleaseTimeMillis] is the autorelease timeout in milliseconds. The value is used only for testing purposes.
  PowerAuthRequestEncryptor({
    required this.encryptorScope,
    required this.powerAuthInstanceId,
    this.autoReleaseTimeMillis,
  });

  @override
  @protected
  Future<String> createNativeObject() async {
    return _platform.initialize(
      scope: encryptorScope,
      powerAuthInstanceId: powerAuthInstanceId,
      autoReleaseTimeMillis: autoReleaseTimeMillis,
    );
  }

  @override
  @protected
  Future<void> releaseNativeObject(String objectId) async {
    return _platform.release(objectId);
  }

  @override
  Future<bool> canEncryptRequest() async {
    try {
      return await withObjectId((id) => _platform.canEncryptRequest(id));
    } catch (e) {
      return false;
    }
  }

  @override
  Future<PowerAuthEncryptedRequestData> encryptRequest(
    String body, [
    PowerAuthDataFormat bodyFormat = PowerAuthDataFormat.utf8,
  ]) async {
    return await withObjectId((id) async {
      final result = await _platform.encryptRequest(id, body, bodyFormat);
      return PowerAuthEncryptedRequestData(
        cryptogram: PowerAuthCryptogram.fromMap(result['cryptogram']),
        header: PowerAuthEncryptionHttpHeader.fromMap(result['header']),
        decryptor: PowerAuthResponseDecryptor(
          decryptorScope: encryptorScope,
          objectId: result['decryptorId'],
        ),
      );
    });
  }
}

/// Implementation of [PowerAuthDecryptor] that uses the platform interface.
class PowerAuthResponseDecryptor extends BaseReleasableObject
    implements PowerAuthDecryptor {

  static PowerAuthEncryptorPlatform get _platform =>
      PowerAuthEncryptorPlatform.instance;

  /// Scope of this decryptor.
  @override
  final PowerAuthEncryptorScope decryptorScope;

  /// Creates a new instance of [PowerAuthResponseDecryptor].
  ///
  /// [decryptorScope] is the original scope used in the encryptor.
  /// [objectId] is the native object identifier.
  PowerAuthResponseDecryptor({
    required this.decryptorScope,
    required String objectId,
  }) {
    this.objectId = objectId;
  }

  @override
  @protected
  Future<void> releaseNativeObject(String objectId) async {
    return _platform.release(objectId);
  }

  @override
  Future<bool> canDecryptResponse() async {
    try {
      return await withObjectId((id) => _platform.canDecryptResponse(id));
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String> decryptResponse(
    PowerAuthCryptogram cryptogram, [
    PowerAuthDataFormat outputDataFormat = PowerAuthDataFormat.utf8,
  ]) async {
    return await withObjectId(
      (id) =>
          _platform.decryptResponse(id, cryptogram.toMap(), outputDataFormat),
    );
  }
}
