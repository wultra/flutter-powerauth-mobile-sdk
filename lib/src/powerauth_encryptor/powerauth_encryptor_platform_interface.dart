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

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../model/powerauth_data_format.dart';
import '../model/powerauth_encryptor.dart';
import 'powerauth_encryptor_method_channel.dart';

/// Platform interface for [PowerAuthEncryptor].
abstract class PowerAuthEncryptorPlatform extends PlatformInterface {

  PowerAuthEncryptorPlatform() : super(token: _token);

  static final Object _token = Object();

  static PowerAuthEncryptorPlatform _instance =
      MethodChannelPowerAuthEncryptor();

  /// The default instance of [PowerAuthEncryptorPlatform] to use.
  static PowerAuthEncryptorPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PowerAuthEncryptorPlatform] when
  /// they register themselves.
  static set instance(PowerAuthEncryptorPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Initialize a new encryptor instance.
  Future<String> initialize({
    required PowerAuthEncryptorScope scope,
    required String powerAuthInstanceId,
    int? autoReleaseTimeMillis,
  }) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Release the encryptor instance.
  Future<void> release(String objectId) {
    throw UnimplementedError('release() has not been implemented.');
  }

  /// Check if the encryptor can encrypt a request.
  Future<bool> canEncryptRequest(String objectId) {
    throw UnimplementedError('canEncryptRequest() has not been implemented.');
  }

  /// Encrypt a request.
  Future<Map<String, dynamic>> encryptRequest(
    String objectId,
    String body,
    PowerAuthDataFormat bodyFormat,
  ) {
    throw UnimplementedError('encryptRequest() has not been implemented.');
  }

  /// Check if the decryptor can decrypt a response.
  Future<bool> canDecryptResponse(String objectId) {
    throw UnimplementedError('canDecryptResponse() has not been implemented.');
  }

  /// Decrypt a response.
  Future<String> decryptResponse(
    String objectId,
    Map<String, dynamic> cryptogram,
    PowerAuthDataFormat outputDataFormat,
  ) {
    throw UnimplementedError('decryptResponse() has not been implemented.');
  }
}
