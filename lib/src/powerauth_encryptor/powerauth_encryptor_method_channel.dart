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

import 'package:flutter/services.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/src/utils/method_channel_helper.dart';
import 'package:meta/meta.dart';

import '../model/powerauth_encryptor.dart';
import 'powerauth_encryptor_platform_interface.dart';

/// Method-channel implementation of [PowerAuthEncryptorPlatform].
class MethodChannelPowerAuthEncryptor extends PowerAuthEncryptorPlatform
    with MethodChannelHelper {
  @visibleForTesting
  @override
  final methodChannel = const MethodChannel('powerauth_plugin');

  @override
  Future<String> initialize({
    required PowerAuthEncryptorScope scope,
    required String powerAuthInstanceId,
  }) {
    return invokeMethod<String>('encryptor_initialize', {
      'scope': scope.name,
      'powerAuthInstanceId': powerAuthInstanceId,
    });
  }

  @override
  Future<void> release(String objectId) async {
    await invokeNullableMethod<void>('encryptor_release', {
      'objectId': objectId,
    });
  }

  @override
  Future<bool> canEncryptRequest(String objectId) {
    return invokeMethod<bool>('encryptor_canEncryptRequest', {
      'objectId': objectId,
    });
  }

  @override
  Future<Map<dynamic, dynamic>> encryptRequest(
    String objectId,
    Uint8List? requestBody,
  ) {
    return invokeMethod<Map<dynamic, dynamic>>('encryptor_encryptRequest', {
      'objectId': objectId,
      'requestBody': requestBody,
    });
  }

  @override
  Future<bool> canDecryptResponse(String objectId) {
    return invokeMethod<bool>('encryptor_canDecryptResponse', {
      'objectId': objectId,
    });
  }

  @override
  Future<Uint8List> decryptResponse(String objectId, Uint8List responseBody) {
    return invokeMethod<Uint8List>('encryptor_decryptResponse', {
      'objectId': objectId,
      'responseBody': responseBody,
    });
  }
}
