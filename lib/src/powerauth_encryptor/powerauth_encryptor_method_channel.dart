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

import 'package:flutter/services.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/src/utils/method_channel_helper.dart';
import 'package:meta/meta.dart';

import '../model/powerauth_data_format.dart';
import '../model/powerauth_encryptor.dart';
import 'powerauth_encryptor_platform_interface.dart';

/// An implementation of [PowerAuthEncryptorPlatform] that uses method channels.
class MethodChannelPowerAuthEncryptor extends PowerAuthEncryptorPlatform with MethodChannelHelper {

  @visibleForTesting
  @override
  final methodChannel = const MethodChannel('powerauth_plugin');

  @override
  Future<String> initialize({
    required PowerAuthEncryptorScope scope,
    required String powerAuthInstanceId,
    int? autoReleaseTimeMillis,
  }) async {
    final objectId = await invokeMethod<String>('encryptor_initialize', {
      'scope': scope.name,
      'powerAuthInstanceId': powerAuthInstanceId,
      'autoReleaseTimeMillis': autoReleaseTimeMillis,
    });

    return objectId;
  }

  @override
  Future<void> release(String objectId) async {
    await invokeMethod('encryptor_release', {'objectId': objectId});
  }

  @override
  Future<bool> canEncryptRequest(String objectId) async {
    final result = await invokeMethod<bool>('encryptor_canEncryptRequest', {
      'objectId': objectId,
    });

    return result;
  }

  @override
  Future<Map> encryptRequest(
    String objectId,
    String body,
    PowerAuthDataFormat bodyFormat,
  ) async {
    final result = await invokeMethod<Map>(
      'encryptor_encryptRequest',
      {'objectId': objectId, 'body': body, 'bodyFormat': bodyFormat.name},
    );

    return result;
  }

  @override
  Future<bool> canDecryptResponse(String objectId) async {
    return await invokeMethod<bool>('encryptor_canDecryptResponse', {
      'objectId': objectId,
    });
  }

  @override
  Future<String> decryptResponse(
    String objectId,
    Map<String, dynamic> cryptogram,
    PowerAuthDataFormat outputDataFormat,
  ) async {
    final result = await invokeMethod<String>('encryptor_decryptResponse', {
      'objectId': objectId,
      'cryptogram': cryptogram,
      'outputDataFormat': outputDataFormat.name,
    });

    return result;
  }
}
