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

import 'package:flutter_powerauth_mobile_sdk_plugin/src/model/powerauth_external_pending_operation.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/src/model/powerauth_user_info.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../logging/powerauth_logging_config.dart';
import '../model/powerauth_activation.dart';
import '../model/powerauth_activation_status.dart';
import '../model/powerauth_algorithm.dart';
import '../model/powerauth_authentication.dart';
import '../model/powerauth_http_header.dart';
import '../model/powerauth_biometric_status.dart';
import '../model/powerauth_biometry_configuration.dart';
import '../model/powerauth_client_configuration.dart';
import '../model/powerauth_configuration.dart';
import '../model/powerauth_create_activation_result.dart';
import '../model/powerauth_keychain_configuration.dart';
import '../model/powerauth_sharing_configuration.dart';
import '../model/powerauth_signature_key_id.dart';
import '../model/powerauth_protocol_upgrade_result.dart';
import '../powerauth_password/powerauth_password.dart';
import 'powerauth_method_channel.dart';

/// An internal platform interface for core PowerAuth SDK functionalities.
abstract class PowerAuthPlatform extends PlatformInterface {
  PowerAuthPlatform() : super(token: _token);

  static final Object _token = Object();

  static PowerAuthPlatform _instance = PowerAuthMethodChannel();

  /// The default instance of [PowerAuthPlatform] to use.
  /// Defaults to [PowerAuthMethodChannel].
  static PowerAuthPlatform get instance => _instance;

  static set instance(PowerAuthPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> configureNativeLogging(PowerAuthLoggingConfig config) {
    throw UnimplementedError(
      'configureNativeLogging() has not been implemented.',
    );
  }

  Future<PowerAuthAuthentication> resolveAuthentication(String instanceId, PowerAuthAuthentication authentication, {bool makeReusable = false}) {
    throw UnimplementedError(
      'resolveAuthentication() has not been implemented.',
    );
  }

  Future<void> configure({
    required String instanceId,
    required PowerAuthConfiguration configuration,
    PowerAuthClientConfiguration? clientConfiguration,
    PowerAuthBiometryConfiguration? biometryConfiguration,
    PowerAuthKeychainConfiguration? keychainConfiguration,
    PowerAuthSharingConfiguration? sharingConfiguration,
  }) {
    throw UnimplementedError('configure() has not been implemented.');
  }

  Future<bool> isConfigured(String instanceId) {
    throw UnimplementedError('isConfigured() has not been implemented.');
  }

  Future<PowerAuthConfiguration> getConfiguration(String instanceId) {
    throw UnimplementedError('getConfiguration() has not been implemented.');
  }

  Future<PowerAuthAlgorithm> getCurrentAlgorithm(String instanceId) {
    throw UnimplementedError('getCurrentAlgorithm() has not been implemented.');
  }

  // TODO: Implement when SDK 2.0.0 is available
  // Future<PowerAuthClientConfiguration> getClientConfiguration(String instanceId) {
  //   throw UnimplementedError('getClientConfiguration() has not been implemented.');
  // }
  //
  // Future<PowerAuthBiometryConfiguration> getBiometryConfiguration(String instanceId) {
  //   throw UnimplementedError('getBiometryConfiguration() has not been implemented.');
  // }
  //
  // Future<PowerAuthKeychainConfiguration> getKeychainConfiguration(String instanceId) {
  //   throw UnimplementedError('getKeychainConfiguration() has not been implemented.');
  // }
  //
  // Future<PowerAuthSharingConfiguration> getSharingConfiguration(String instanceId) {
  //   throw UnimplementedError('getSharingConfiguration() has not been implemented.');
  // }
  //
  Future<void> deconfigure(String instanceId) {
    throw UnimplementedError('deconfigure() has not been implemented.');
  }

  Future<bool> hasValidActivation(String instanceId) {
    throw UnimplementedError('hasValidActivation() has not been implemented.');
  }

  Future<bool> canStartActivation(String instanceId) {
    throw UnimplementedError('canStartActivation() has not been implemented.');
  }

  Future<bool> hasPendingActivation(String instanceId) {
    throw UnimplementedError(
      'hasPendingActivation() has not been implemented.',
    );
  }

  Future<PowerAuthExternalPendingOperation?> getExternalPendingOperation(String instanceId) {
    throw UnimplementedError('getExternalPendingOperation() has not been implemented.');
  }

  Future<String?> getActivationIdentifier(String instanceId) {
    throw UnimplementedError(
      'getActivationIdentifier() has not been implemented.',
    );
  }

  Future<String?> getActivationFingerprint(String instanceId) {
    throw UnimplementedError(
      'getActivationFingerprint() has not been implemented.',
    );
  }

  Future<PowerAuthActivationStatus> fetchActivationStatus(String instanceId) {
    throw UnimplementedError(
      'fetchActivationStatus() has not been implemented.',
    );
  }

  Future<bool> hasProtocolUpgradeAvailable(String instanceId) {
    throw UnimplementedError(
      'hasProtocolUpgradeAvailable() has not been implemented.',
    );
  }

  Future<PowerAuthProtocolUpgradeResult> startProtocolUpgrade(
    String instanceId,
    PowerAuthPassword password, {
    bool upgradeBiometry = false,
  }) {
    throw UnimplementedError(
      'startProtocolUpgrade() has not been implemented.',
    );
  }

  Future<void> removeActivationLocal(String instanceId) {
    throw UnimplementedError(
      'removeActivationLocal() has not been implemented.',
    );
  }

  Future<void> removeActivationWithAuthentication(
    String instanceId,
    PowerAuthAuthentication authentication,
  ) {
    throw UnimplementedError(
      'removeActivationWithAuthentication() has not been implemented.',
    );
  }

  Future<PowerAuthCreateActivationResult> createActivation(
    String instanceId,
    PowerAuthActivation activation,
  ) {
    throw UnimplementedError('createActivation() has not been implemented.');
  }

  Future<void> persistActivation(
    String instanceId,
    PowerAuthAuthentication authentication,
  ) {
    throw UnimplementedError('persistActivation() has not been implemented.');
  }

  Future<String> beginPasswordChange(
    String instanceId,
    PowerAuthPassword oldPassword,
  ) {
    throw UnimplementedError('beginPasswordChange() has not been implemented.');
  }

  Future<void> finishPasswordChange(
    String instanceId,
    PowerAuthPassword newPassword,
    String passwordChangeData,
  ) {
    throw UnimplementedError('finishPasswordChange() has not been implemented.');
  }

  Future<PowerAuthHttpHeader> requestGetSignature(
    String instanceId,
    PowerAuthAuthentication authentication,
    String uriId, [
    Map<String, String>? queryParams,
  ]) {
    throw UnimplementedError('requestGetSignature() has not been implemented.');
  }

  Future<PowerAuthHttpHeader> requestSignature(
    String instanceId,
    PowerAuthAuthentication authentication,
    String method,
    String uriId, [
    Uint8List? body,
  ]) {
    throw UnimplementedError('requestSignature() has not been implemented.');
  }

  Future<String> offlineSignature(
    String instanceId,
    PowerAuthAuthentication authentication,
    String uriId,
    String nonce, [
    Uint8List? body,
  ]) {
    throw UnimplementedError('offlineSignature() has not been implemented.');
  }

  Future<void> verifyDigitalSignature(
    String instanceId,
    Uint8List signature,
    Uint8List data,
    PowerAuthSignatureKeyId signatureKeyId,
  ) {
    throw UnimplementedError(
      'verifyDigitalSignature() has not been implemented.',
    );
  }

  Future<Uint8List> calculateDigitalSignature(
    String instanceId,
    PowerAuthAuthentication authentication,
    Uint8List data,
    PowerAuthSignatureKeyId signatureKeyId,
  ) {
    throw UnimplementedError(
      'calculateDigitalSignature() has not been implemented.',
    );
  }

  Future<void> verifyJwsSignature(
    String instanceId,
    String signature,
    bool compact,
    bool strict,
    PowerAuthSignatureKeyId signatureKeyId,
  ) {
    throw UnimplementedError(
      'verifyJwsSignature() has not been implemented.',
    );
  }

  Future<String> calculateJwsSignature(
    String instanceId,
    PowerAuthAuthentication authentication,
    Uint8List data,
    String? dataType,
    bool compact,
    PowerAuthSignatureKeyId signatureKeyId,
  ) {
    throw UnimplementedError(
      'calculateJwsSignature() has not been implemented.',
    );
  }

  Future<String> createCertificateSigningRequest(
    String instanceId,
    PowerAuthAuthentication authentication,
    Map<String, String> distinguishedNames,
    List<String>? subjectAltNames,
    PowerAuthSignatureKeyId signatureKeyId,
  ) {
    throw UnimplementedError(
      'createCertificateSigningRequest() has not been implemented.',
    );
  }

  Future<void> addBiometryFactor(
    String instanceId,
    PowerAuthPassword password, [
    PowerAuthBiometricPrompt? prompt,
  ]) {
    throw UnimplementedError('addBiometryFactor() has not been implemented.');
  }

  Future<bool> hasBiometryFactor(String instanceId) {
    throw UnimplementedError('hasBiometryFactor() has not been implemented.');
  }

  Future<PowerAuthBiometricStatus> getBiometricStatus(String instanceId) {
    throw UnimplementedError('getBiometricStatus() has not been implemented.');
  }

  Future<bool> isAuthenticationWithBiometricsAvailable(String instanceId) {
    throw UnimplementedError('isAuthenticationWithBiometricsAvailable() has not been implemented.');
  }

  Future<void> removeBiometryFactor(String instanceId) {
    throw UnimplementedError('removeBiometryFactor() has not been implemented.');
  }

  Future<Uint8List> fetchEncryptionKey(String instanceId, PowerAuthAuthentication authentication, int index) {
    throw UnimplementedError('fetchEncryptionKey() has not been implemented.');
  }

  Future<String> fetchSecureVaultKey(String instanceId, PowerAuthAuthentication authentication, String keyIdentifier) {
    throw UnimplementedError('fetchSecureVaultKey() has not been implemented.');
  }

  Future<Uint8List> deriveSecureVaultKey(String objectId, int index, int keySize) {
    throw UnimplementedError('deriveSecureVaultKey() has not been implemented.');
  }


  Future<bool> hasLocalToken(String instanceId, String tokenName) {
    throw UnimplementedError('hasLocalToken() has not been implemented.');
  }

  Future<Map> getLocalToken(String instanceId, String tokenName) {
    throw UnimplementedError('getLocalToken() has not been implemented.');
  }

  Future<void> removeLocalToken(String instanceId, String tokenName) {
    throw UnimplementedError('removeLocalToken() has not been implemented.');
  }

  Future<void> removeAllLocalTokens(String instanceId) {
    throw UnimplementedError('removeAllLocalTokens() has not been implemented.');
  }

  Future<Map> requestAccessToken(String instanceId, String tokenName, PowerAuthAuthentication authentication) {
    throw UnimplementedError('requestAccessToken() has not been implemented.');
  }

  Future<void> removeAccessToken(String instanceId, String tokenName) {
    throw UnimplementedError('removeAccessToken() has not been implemented.');
  }

  Future<PowerAuthHttpHeader> generateHeaderForToken(String instanceId, String tokenName) {
    throw UnimplementedError('generateHeaderForToken() has not been implemented.');
  }

  Future<PowerAuthUserInfo> fetchUserInfo(String instanceId) {
    throw UnimplementedError('fetchUserInfo() has not been implemented.');
  }

  Future<PowerAuthUserInfo?> getLastFetchedUserInfo(String instanceId) {
    throw UnimplementedError('getLastFetchedUserInfo() has not been implemented.');
  }

  Future<bool> isTimeSynchronized(String instanceId) {
    throw UnimplementedError('isTimeSynchronized() has not been implemented.');
  }

  Future<int> localTimeAdjustment(String instanceId) {
    throw UnimplementedError('localTimeAdjustment() has not been implemented.');
  }

  Future<int> localTimeAdjustmentPrecision(String instanceId) {
    throw UnimplementedError('localTimeAdjustmentPrecision() has not been implemented.');
  }

  Future<int> currentTime(String instanceId) {
    throw UnimplementedError('currentTime() has not been implemented.');
  }

  Future<void> synchronizeTime(String instanceId) {
    throw UnimplementedError('synchronizeTime() has not been implemented.');
  }

  Future<void> resetTimeSynchronization(String instanceId) {
    throw UnimplementedError('resetTimeSynchronization() has not been implemented.');
  }
}
