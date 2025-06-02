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
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/src/model/powerauth_authentication_internal.dart';

import 'powerauth_platform_interface.dart';

import '../utils/method_channel_helper.dart';


/// An implementation of [PowerAuthPlatform] that uses method channels.
class PowerAuthMethodChannel extends PowerAuthPlatform with MethodChannelHelper {

  @override
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel('powerauth_plugin');

  static MethodChannel get sharedChannel => (PowerAuthPlatform.instance as PowerAuthMethodChannel).methodChannel;

  @override
  Future<PowerAuthAuthentication> resolveAuthentication(String instanceId, PowerAuthAuthentication authentication, {bool makeReusable = false}) async {

    final auth = authentication as InternalAuth?;

    if (auth == null) {
      throw PowerAuthException(code: PowerAuthErrorCode.unknownError, message: "PowerAuthAuthentication must be an InternalAuth instance for method channel operations.");
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
      try {
        final isReusable = auth.isReusable || makeReusable;
        auth.isReusable = isReusable;
        auth.biometryKeyId = await invokeNullableMethod<String>('authenticateWithBiometry', {
          'instanceId': instanceId,
          'prompt': auth.biometricPrompt?.toMap(),
          'isReusable': isReusable,
        });
      } catch (e) {
        // TODO: better processing?
        rethrow;
      }
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
  Future<void> removeActivationWithAuthentication(String instanceId, PowerAuthAuthentication authentication) async {
    final resolvedAuth = await resolveAuthentication(instanceId, authentication);
    final args = await resolvedAuth.prepareAuthArguments({'instanceId': instanceId});
    await invokeMethod<void>('removeActivationWithAuthentication', args);
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
    final args = await authentication.prepareAuthArguments({'instanceId': instanceId});
    await invokeMethod<void>('persistActivation', args);
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
    final resolvedAuth = await resolveAuthentication(instanceId, authentication);
    final args = await resolvedAuth.prepareAuthArguments({
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
    final resolvedAuth = await resolveAuthentication(instanceId, authentication);
    final args = await resolvedAuth.prepareAuthArguments({
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
    final resolvedAuth = await resolveAuthentication(instanceId, authentication);
    final args = await resolvedAuth.prepareAuthArguments({
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
    final resolvedAuth = await resolveAuthentication(instanceId, authentication);
    final args = await resolvedAuth.prepareAuthArguments({
      'instanceId': instanceId,
      'tokenName': tokenName,
    });
    return await invokeMethod('requestAccessToken', args);
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

  // TODO: remove this debug call before release!
  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
