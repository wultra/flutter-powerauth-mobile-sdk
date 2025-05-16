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
import '../model/powerauth_client_configuration.dart';
import '../model/powerauth_keychain_configuration.dart';
import '../model/powerauth_sharing_configuration.dart';
import '../powerauth_password/powerauth_password.dart';
import 'powerauth_platform_interface.dart';

import '../utils/method_channel_helper.dart';

import '../model/powerauth_activation.dart';
import '../model/powerauth_activation_status.dart';
import '../model/powerauth_authentication.dart';
import '../model/powerauth_authorization_http_header.dart';
import '../model/powerauth_configuration.dart';
import '../model/powerauth_create_activation_result.dart';

/// An implementation of [PowerAuthPlatform] that uses method channels.
class PowerAuthMethodChannel extends PowerAuthPlatform
    with MethodChannelHelper {

  // TODO: temp internal cache for the temporary biometric key handle - purge this with fire when we have ObjectRegister
  String? _cachedBiometryKeyId;

  @override
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel('powerauth_plugin');

  static MethodChannel get sharedChannel =>
      (PowerAuthPlatform.instance as PowerAuthMethodChannel).methodChannel;

  // Hacky helper to prepare arguments, potentially triggering biometry and injecting key ID
  Future<Map<String, dynamic>> _prepareAuthArguments(
    String instanceId, // Need instanceId here
    PowerAuthAuthentication authentication,
    Map<String, dynamic> baseArgs,
  ) async {
    final args = Map<String, dynamic>.from(baseArgs);
    final authMap = await authentication.toMap();

    // Trigger biometry and inject key ID if needed - this kinda mimics the AuthResolver from rN
    if (authentication.useBiometry) {
      if (_cachedBiometryKeyId == null) {
        print(
          "Biometry requested, but no cached key ID. Triggering native auth...",
        );

        try {
          final keyId =
              await invokeNullableMethod<String>('authenticateWithBiometry', {
                'instanceId': instanceId,
                'prompt': authentication.biometricPrompt?.toMap(),
              });

          if (keyId != null) {
            print("Native biometric auth successful, caching key ID: $keyId");
            _cachedBiometryKeyId = keyId; // Cache the new key ID
          } else {
            print(
              "Warning: Native biometric auth returned null key ID without throwing.",
            );
          }
        } catch (e) {
          print("Native biometric auth failed during argument preparation: $e");
          _cachedBiometryKeyId = null;
          rethrow;
        }
      }

      // Inject the ID if we actually have it
      if (_cachedBiometryKeyId != null) {
        print("Injecting cached biometry key ID: $_cachedBiometryKeyId");

        authMap['biometryKeyId'] = _cachedBiometryKeyId;
        _cachedBiometryKeyId = null;
      } else {
        // TODO: not sure here, will this result in a simple possession? 
        print("Proceeding with biometry request without a specific key ID.");
      }
    }

    args['authentication'] = authMap;
    return args;
  }

  @override
  Future<void> configure({
    required String instanceId,
    required PowerAuthConfiguration configuration,
    PowerAuthClientConfiguration? clientConfiguration,
    PowerAuthBiometryConfiguration? biometryConfiguration,
    PowerAuthKeychainConfiguration? keychainConfiguration,
    PowerAuthSharingConfiguration? sharingConfiguration,
  }) async {
    await invokeMethod<void>('configure', {
      'instanceId': instanceId,
      'configuration': configuration.toMap(),
      'clientConfiguration': clientConfiguration?.toMap(),
      'biometryConfiguration': biometryConfiguration?.toMap(),
      'keychainConfiguration': keychainConfiguration?.toMap(),
      'sharingConfiguration': sharingConfiguration?.toMap(),
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
    final args = await _prepareAuthArguments(instanceId, authentication, {
      'instanceId': instanceId,
    });
    await invokeMethod<void>('removeActivationWithAuthentication', args);
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
      'authentication': await authentication.toMap()
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
    final args = await _prepareAuthArguments(instanceId, authentication, {
      'instanceId': instanceId,
      'uriId': uriId,
      'queryParams': queryParams
    });

    final result = await invokeMethod<Map<dynamic, dynamic>>(
      'requestGetSignature',
      args
    );
    return PowerAuthAuthorizationHttpHeader.fromMap(result);
  }

  @override
  Future<PowerAuthAuthorizationHttpHeader> requestSignature(
    String instanceId,
    PowerAuthAuthentication authentication,
    String method,
    String uriId, [
    String? body
  ]) async {
    final args = await _prepareAuthArguments(instanceId, authentication, {
      'instanceId': instanceId,
      'method': method,
      'uriId': uriId,
      'body': body
    });

    final result = await invokeMethod<Map<dynamic, dynamic>>(
      'requestSignature',
      args
    );
    return PowerAuthAuthorizationHttpHeader.fromMap(result);
  }

  @override
  Future<String> offlineSignature(
    String instanceId,
    PowerAuthAuthentication authentication,
    String uriId,
    String nonce, [
    String? body
  ]) async {
    final args = await _prepareAuthArguments(instanceId, authentication, {
      'instanceId': instanceId,
      'uriId': uriId,
      'nonce': nonce,
      'body': body
    });

    return await invokeMethod<String>('offlineSignature', args);
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
    _cachedBiometryKeyId = null;

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
    _cachedBiometryKeyId = null;

    await invokeMethod<void>('addBiometryFactor', {
      'instanceId': instanceId,
      'password': await password.toRawPasswordMap(),
      'prompt': prompt?.toMap(),
    });
  }

  @override
  Future<bool> hasBiometryFactor(String instanceId) async {
    // _cachedBiometryKeyId = null;

    return await invokeMethod<bool>('hasBiometryFactor', {
      'instanceId': instanceId,
    });
  }

  @override
  Future<void> removeBiometryFactor(String instanceId) async {
    _cachedBiometryKeyId = null;

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
