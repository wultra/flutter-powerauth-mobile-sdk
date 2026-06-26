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

import '../../flutter_powerauth_mobile_sdk_plugin.dart';
import '../model/powerauth_authentication_internal.dart';
import '../model/powerauth_external_pending_operation.dart';
import '../model/powerauth_instance_configuration_holder.dart';
import 'powerauth_platform_interface.dart';

import '../utils/method_channel_helper.dart';

/// An implementation of [PowerAuthPlatform] that uses method channels.
class PowerAuthMethodChannel extends PowerAuthPlatform with MethodChannelHelper {

  @override
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel('powerauth_plugin');

  @override
  Future<void> configureNativeLogging(PowerAuthLoggingConfig config) async {
    await invokeMethod<void>('logging_configure', config.toMap());
  }

  @override
  Future<PowerAuthAuthentication> resolveAuthentication(String instanceId, PowerAuthAuthentication authentication, {bool makeReusable = false}) async {

    // We expect that the authentication object is an instance of InternalAuth,
    // which is used for method channel operations. If it's not, we throw an exception.
    final auth = authentication as InternalAuth?;

    if (auth == null) {
      throw PowerAuthException(code: PowerAuthErrorCode.unknownError, message: "PowerAuthAuthentication must be an InternalAuth instance for method channel operations.");
    }

    // If the authentication is for activation persist, we return it directly (persist does not need biometric authentication).
    if (auth.forActivationPersist) {
      return auth;
    }

    // Test whether previously fetched biometryKeyId is invalid. Reset biometry key's identifier
    // if underlying data object is no longer valid.
    if (auth.isReusable && auth.biometryKeyId != null) {
      final isValid = await NativeObjectRegister.isValidNativeObject(auth.biometryKeyId!);
      if (isValid == false) {
        auth.biometryKeyId = null;
      }
    }

    // On both platforms we need to fetch the key for every biometric authentication.
    // If the key is already set, use it.
    if (auth.useBiometry && auth.biometryKeyId == null) {
      final isReusable = auth.isReusable || makeReusable;
      auth.isReusable = isReusable;
      auth.biometryKeyId = await invokeNullableMethod<String>('authenticateWithBiometry', {
        'instanceId': instanceId,
        'prompt': auth.biometricPrompt?.toMap(),
        'isReusable': isReusable,
      });
    }
    return auth;
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
  Future<PowerAuthInstanceConfigurationHolder> getConfiguration(String instanceId) async {
    final result = await invokeMethod<Map<dynamic, dynamic>>('getConfiguration', {'instanceId': instanceId});
    return PowerAuthInstanceConfigurationHolder.fromMap(result);
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
  Future<PowerAuthExternalPendingOperation?> getExternalPendingOperation(String instanceId) async {
    final result = await invokeNullableMethod<Map<dynamic, dynamic>>('getExternalPendingOperation', {
      'instanceId': instanceId,
    });
    if (result == null) {
      return null;
    }
    return PowerAuthExternalPendingOperation.fromMap(result);
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
  Future<void> removeActivationWithAuthentication(String instanceId, PowerAuthAuthentication authentication) async {
    await invokeMethod<void>('removeActivationWithAuthentication', await _authenticate(instanceId, authentication, {'instanceId': instanceId}));
  }

  @override
  Future<PowerAuthCreateActivationResult> createActivation(String instanceId, PowerAuthActivation activation) async {
    final result = await invokeMethod<Map<dynamic, dynamic>>(
      'createActivation',
      {'instanceId': instanceId, 'activation': activation.toMap()},
    );
    return PowerAuthCreateActivationResult.fromMap(result);
  }

  @override
  Future<void> persistActivation(String instanceId, PowerAuthAuthentication authentication) async {
    await invokeMethod<void>('persistActivation', await _authenticate(instanceId, authentication, {'instanceId': instanceId}));
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
    final result = await invokeMethod<Map<dynamic, dynamic>>(
      'requestGetSignature',
      await _authenticate(instanceId, authentication, {
        'instanceId': instanceId,
        'uriId': uriId,
        'queryParams': queryParams
      })
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
    final result = await invokeMethod<Map<dynamic, dynamic>>(
      'requestSignature',
      await _authenticate(instanceId, authentication, {
        'instanceId': instanceId,
        'method': method,
        'uriId': uriId,
        'body': body
      })
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
    return await invokeMethod<String>('offlineSignature', await _authenticate(instanceId, authentication, {
      'instanceId': instanceId,
      'uriId': uriId,
      'nonce': nonce,
      'body': body
    }));
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
  Future<PowerAuthBiometryInfo> getBiometryInfo() async {
    final result = await invokeMethod<Map<dynamic, dynamic>>('getBiometryInfo', null);
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
      'password': await password.toRawPasswordMap(),
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

  @override
  Future<String> fetchEncryptionKey(String instanceId, PowerAuthAuthentication authentication, int index) async {
    return await invokeMethod<String>('fetchEncryptionKey', await _authenticate(instanceId, authentication, {
      'instanceId': instanceId,
      'index': index
    }));
  }

  @override
  Future<String> signDataWithDevicePrivateKey(String instanceId, PowerAuthAuthentication authentication, String data, PowerAuthDataFormat dataFormat) async {
    return await invokeMethod<String>('signDataWithDevicePrivateKey', await _authenticate(instanceId, authentication, {
      'instanceId': instanceId,
      'data': data,
      'dataFormat': dataFormat.name,
    }));
  }

  @override
  Future<bool> hasLocalToken(String instanceId, String tokenName) async {
    return await invokeMethod('hasLocalToken', {
      'instanceId': instanceId,
      'tokenName': tokenName,
    });
  }

  @override
  Future<Map> getLocalToken(String instanceId, String tokenName) async {
    return await invokeMethod('getLocalToken', {
      'instanceId': instanceId,
      'tokenName': tokenName,
    });
  }

  @override
  Future<void> removeLocalToken(String instanceId, String tokenName) async {
    await invokeMethod<void>('removeLocalToken', {
      'instanceId': instanceId,
      'tokenName': tokenName,
    });
  }

  @override
  Future<void> removeAllLocalTokens(String instanceId) async {
    await invokeMethod<void>('removeAllLocalTokens', {
      'instanceId': instanceId,
    });
  }

  @override
  Future<Map> requestAccessToken(String instanceId, String tokenName, PowerAuthAuthentication authentication) async {
    return await invokeMethod('requestAccessToken', await _authenticate(instanceId, authentication, {
      'instanceId': instanceId,
      'tokenName': tokenName,
    }));
  }

  @override
  Future<void> removeAccessToken(String instanceId, String tokenName) async {
    await invokeMethod('removeAccessToken', {
      'instanceId': instanceId,
      'tokenName': tokenName,
    });
  }

  @override
  Future<Map> generateHeaderForToken(String instanceId, String tokenName) async {
    return await invokeMethod('generateHeaderForToken', {
      'instanceId': instanceId,
      'tokenName': tokenName,
    });
  }

  @override
  Future<PowerAuthUserInfo> fetchUserInfo(String instanceId) async {
    final result = await invokeMethod<Map<dynamic, dynamic>>('fetchUserInfo', {
      'instanceId': instanceId,
    });
    return PowerAuthUserInfo(result['allClaims'] as Map?);
  }

  @override
  Future<PowerAuthUserInfo?> getLastFetchedUserInfo(String instanceId) async {
    final result = await invokeNullableMethod<Map<dynamic, dynamic>>('getLastFetchedUserInfo', {
      'instanceId': instanceId,
    });
    if (result == null) {
      return null;
    }
    return PowerAuthUserInfo(result['allClaims'] as Map?);
  }

  @override
  Future<bool> isTimeSynchronized(String instanceId) async {
    return await invokeMethod('isTimeSynchronized', {
      'instanceId': instanceId
    });
  }

  @override
  Future<int> localTimeAdjustment(String instanceId) async {
    return await invokeMethod('localTimeAdjustment', {
      'instanceId': instanceId
    });
  }

  @override
  Future<int> localTimeAdjustmentPrecision(String instanceId) async {
    return await invokeMethod('localTimeAdjustmentPrecision', {
      'instanceId': instanceId
    });
  }

  @override
  Future<int> currentTime(String instanceId) async {
    return await invokeMethod('currentTime', {
      'instanceId': instanceId
    });
  }

  @override
  Future<void> synchronizeTime(String instanceId) async {
    await invokeMethod('synchronizeTime', {
      'instanceId': instanceId
    });
  }
  
  @override
  Future<void> resetTimeSynchronization(String instanceId) async {
    await invokeMethod('resetTimeSynchronization', {
      'instanceId': instanceId
    });
  }

  Future<Map<String, dynamic>> _authenticate(String instanceId, PowerAuthAuthentication authentication, Map<String, dynamic> baseArgs) async {
    final resolvedAuth = await resolveAuthentication(instanceId, authentication);
    return await resolvedAuth.prepareAuthArguments(baseArgs);
  }
}
