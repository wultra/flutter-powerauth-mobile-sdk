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

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../model/powerauth_biometry_configuration.dart';
import '../model/powerauth_biometry_info.dart';
import '../model/powerauth_keychain_configuration.dart';
import 'powerauth_platform_interface.dart';

import '../utils/method_channel_helper.dart';

import '../model/powerauth_activation.dart';
import '../model/powerauth_activation_status.dart';
import '../model/powerauth_authentication.dart';
import '../model/powerauth_authorization_http_header.dart';
import '../model/powerauth_configuration.dart';
import '../model/powerauth_create_activation_result.dart';
import '../powerauth_password/powerauth_password.dart';

/// An implementation of [PowerAuthPlatform] that uses method channels.
class PowerAuthMethodChannel extends PowerAuthPlatform
    with MethodChannelHelper {

  @override
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel('powerauth_plugin');

  static MethodChannel get sharedChannel =>
      (PowerAuthPlatform.instance as PowerAuthMethodChannel).methodChannel;

  @override
  Future<void> configure({
    required String instanceId,
    required PowerAuthConfiguration configuration,
    PowerAuthBiometryConfiguration? biometryConfiguration,
    PowerAuthKeychainConfiguration? keychainConfiguration,
  }) async {
    await invokeMethod<void>('configure', {
      'instanceId': instanceId,
      'configuration': configuration.toMap(),
      'biometryConfiguration': biometryConfiguration?.toMap(),
      'keychainConfiguration': keychainConfiguration?.toMap(),
    });
  }

  @override
  Future<bool> isConfigured(String instanceId) async {
    return await invokeMethod<bool>('isConfigured', {'instanceId': instanceId});
  }

  @override
  Future<void> deconfigure(String instanceId) async {
    await invokeMethod<void>('deconfigure', {'instanceId': instanceId});
  }

  @override
  Future<bool> hasValidActivation(String instanceId) async {
    return await invokeMethod<bool>('hasValidActivation', {
      'instanceId': instanceId,
    });
  }

  @override
  Future<bool> canStartActivation(String instanceId) async {
    return await invokeMethod<bool>('canStartActivation', {
      'instanceId': instanceId,
    });
  }

  @override
  Future<bool> hasPendingActivation(String instanceId) async {
    return await invokeMethod<bool>('hasPendingActivation', {
      'instanceId': instanceId,
    });
  }

  @override
  Future<String?> getActivationIdentifier(String instanceId) async {
    return await invokeNullableMethod<String>('getActivationIdentifier', {
      'instanceId': instanceId,
    });
  }

  @override
  Future<String?> getActivationFingerprint(String instanceId) async {
    return await invokeNullableMethod<String>('getActivationFingerprint', {
      'instanceId': instanceId,
    });
  }

  @override
  Future<PowerAuthActivationStatus> fetchActivationStatus(
    String instanceId,
  ) async {
    final result = await invokeMethod<Map<dynamic, dynamic>>(
      'fetchActivationStatus',
      {'instanceId': instanceId},
    );
    return PowerAuthActivationStatus.fromJson(result);
  }

  @override
  Future<void> removeActivationLocal(String instanceId) async {
    await invokeMethod<void>('removeActivationLocal', {
      'instanceId': instanceId,
    });
  }

  @override
  Future<void> removeActivationWithAuthentication(
    String instanceId,
    PowerAuthAuthentication authentication,
  ) async {
    await invokeMethod<void>('removeActivationWithAuthentication', {
      'instanceId': instanceId,
      'authentication': await authentication.toMap(),
    });
  }

  @override
  Future<PowerAuthCreateActivationResult> createActivation(
    String instanceId,
    PowerAuthActivation activation,
  ) async {
    final result = await invokeMethod<Map<dynamic, dynamic>>(
      'createActivation',
      {'instanceId': instanceId, 'activation': activation.toMap()},
    );
    return PowerAuthCreateActivationResult.fromMap(result);
  }

  @override
  Future<void> persistActivation(
    String instanceId,
    PowerAuthAuthentication authentication,
  ) async {
    await invokeMethod<void>('persistActivation', {
      'instanceId': instanceId,
      'authentication': await authentication.toMap(),
    });
  }

  @override
  Future<void> validatePassword(String instanceId, PowerAuthPassword password) async {
    await invokeMethod<void>('validatePassword', {
      'instanceId': instanceId,
      'password': await password.toRawPasswordMap()
    });
  }

  @override
  Future<void> changePassword(
    String instanceId,
    PowerAuthPassword oldPassword,
    PowerAuthPassword newPassword,
  ) async {
    await invokeMethod<void>('changePassword', {
      'instanceId': instanceId,
      'oldPassword': await oldPassword.toRawPasswordMap(),
      'newPassword': await newPassword.toRawPasswordMap()
    });
  }

  @override
  Future<PowerAuthAuthorizationHttpHeader> requestGetSignature(
    String instanceId,
    PowerAuthAuthentication authentication,
    String uriId, [
    Map<String, String>? queryParams,
  ]) async {
    final result =
        await invokeMethod<Map<dynamic, dynamic>>('requestGetSignature', {
          'instanceId': instanceId,
          'authentication': await authentication.toMap(),
          'uriId': uriId,
          'queryParams': queryParams,
        });
    return PowerAuthAuthorizationHttpHeader.fromMap(result);
  }

  @override
  Future<PowerAuthAuthorizationHttpHeader> requestSignature(
    String instanceId,
    PowerAuthAuthentication authentication,
    String method,
    String uriId, [
    String? body,
  ]) async {
    final result =
        await invokeMethod<Map<dynamic, dynamic>>('requestSignature', {
          'instanceId': instanceId,
          'authentication': await authentication.toMap(),
          'method': method,
          'uriId': uriId,
          'body': body,
        });
    return PowerAuthAuthorizationHttpHeader.fromMap(result);
  }

  @override
  Future<String> offlineSignature(
    String instanceId,
    PowerAuthAuthentication authentication,
    String uriId,
    String nonce, [
    String? body,
  ]) async {
    return await invokeMethod<String>('offlineSignature', {
      'instanceId': instanceId,
      'authentication': await authentication.toMap(),
      'uriId': uriId,
      'nonce': nonce,
      'body': body,
    });
  }

  @override
  Future<bool> verifyServerSignedData(
    String instanceId,
    String data,
    String signature,
    bool useMasterKey,
  ) async {
    return await invokeMethod<bool>('verifyServerSignedData', {
      'instanceId': instanceId,
      'data': data,
      'signature': signature,
      'useMasterKey': useMasterKey,
    });
  }

  @override
  Future<PowerAuthBiometryInfo> getBiometryInfo(String instanceId) async {
    final result = await invokeMethod<Map<dynamic, dynamic>>(
      'getBiometryInfo',
      {'instanceId': instanceId},
    );
    return PowerAuthBiometryInfo.fromMap(result);
  }

  @override
  Future<void> addBiometryFactor(
    String instanceId,
    PowerAuthPassword password, [
    PowerAuthBiometricPrompt? prompt,
  ]) async {
    await invokeMethod<void>('addBiometryFactor', {
      'instanceId': instanceId,
      'password': password.toRawPasswordMap(),
      'prompt': prompt?.toMap(),
    });
  }

  @override
  Future<bool> hasBiometryFactor(String instanceId) async {
    return await invokeMethod<bool>('hasBiometryFactor', {
      'instanceId': instanceId,
    });
  }

  @override
  Future<void> removeBiometryFactor(String instanceId) async {
    await invokeMethod<void>('removeBiometryFactor', {
      'instanceId': instanceId,
    });
  }

  // TODO: remove this debug call before release!
  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
