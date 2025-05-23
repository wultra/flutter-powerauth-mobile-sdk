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

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../model/powerauth_activation.dart';
import '../model/powerauth_activation_status.dart';
import '../model/powerauth_authentication.dart';
import '../model/powerauth_authorization_http_header.dart';
import '../model/powerauth_biometry_configuration.dart';
import '../model/powerauth_biometry_info.dart';
import '../model/powerauth_client_configuration.dart';
import '../model/powerauth_configuration.dart';
import '../model/powerauth_create_activation_result.dart';
import '../model/powerauth_keychain_configuration.dart';
import '../model/powerauth_sharing_configuration.dart';
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

  Future<void> validatePassword(String instanceId, PowerAuthPassword password) {
    throw UnimplementedError('validatePassword() has not been implemented.');
  }

  Future<void> changePassword(
    String instanceId,
    PowerAuthPassword oldPassword,
    PowerAuthPassword newPassword,
  ) {
    throw UnimplementedError('changePassword() has not been implemented.');
  }

  Future<PowerAuthAuthorizationHttpHeader> requestGetSignature(
    String instanceId,
    PowerAuthAuthentication authentication,
    String uriId, [
    Map<String, String>? queryParams,
  ]) {
    throw UnimplementedError('requestGetSignature() has not been implemented.');
  }

  Future<PowerAuthAuthorizationHttpHeader> requestSignature(
    String instanceId,
    PowerAuthAuthentication authentication,
    String method,
    String uriId, [
    String? body,
  ]) {
    throw UnimplementedError('requestSignature() has not been implemented.');
  }

  Future<String> offlineSignature(
    String instanceId,
    PowerAuthAuthentication authentication,
    String uriId,
    String nonce, [
    String? body,
  ]) {
    throw UnimplementedError('offlineSignature() has not been implemented.');
  }

  Future<bool> verifyServerSignedData(
    String instanceId,
    String data,
    String signature,
    bool useMasterKey,
  ) {
    throw UnimplementedError(
      'verifyServerSignedData() has not been implemented.',
    );
  }

  Future<PowerAuthBiometryInfo> getBiometryInfo(String instanceId) {
    throw UnimplementedError('getBiometryInfo() has not been implemented.');
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

  Future<void> removeBiometryFactor(String instanceId) {
    throw UnimplementedError(
      'removeBiometryFactor() has not been implemented.',
    );
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

  Future<Map> generateHeaderForToken(String instanceId, String tokenName) {
    throw UnimplementedError('generateHeaderForToken() has not been implemented.');
  }

  // TODO: remove this debug call before release!
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
