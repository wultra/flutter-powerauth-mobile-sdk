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

import 'package:flutter_powerauth_mobile_sdk_plugin/src/model/powerauth_instance_configuration_holder.dart';

import '../model/powerauth_biometry_configuration.dart';
import '../model/powerauth_biometry_info.dart';
import '../model/powerauth_client_configuration.dart';
import '../model/powerauth_keychain_configuration.dart';
import '../model/powerauth_sharing_configuration.dart';
import '../model/powerauth_user_info.dart';
import 'powerauth_platform_interface.dart';

import '../model/powerauth_activation.dart';
import '../model/powerauth_activation_status.dart';
import '../model/powerauth_authentication.dart';
import '../model/powerauth_authorization_http_header.dart';
import '../model/powerauth_configuration.dart';
import '../powerauth_password/powerauth_password.dart';
import '../model/powerauth_encryptor.dart';
import '../model/powerauth_external_pending_operation.dart';
import '../powerauth_encryptor/powerauth_encryptor.dart';
import 'powerauth_token_store.dart';
import 'powerauth_time_synchronization_service.dart';
import '../model/powerauth_create_activation_result.dart';
import '../model/powerauth_data_format.dart';
import '../model/powerauth_error.dart';
import '../model/powerauth_authentication_internal.dart';

/// Main class for interacting with the PowerAuth Mobile Flutter SDK.
///
/// Use this class to manage activation, authentication, signatures, and other core features.
class PowerAuth {

  /// Unique identifier for this PowerAuth instance.
  final String instanceId;

  /// Instance of the token store object, which provides interface for generating token based authentication headers.
  PowerAuthTokenStore get tokenStore => _tokenStore;
  final PowerAuthTokenStore _tokenStore;

  /// Object providing functions to synchronize time with the server.
  PowerAuthTimeSynchronizationService get timeSynchronizationService => _timeSynchronizationService;
  final PowerAuthTimeSynchronizationService _timeSynchronizationService;

  /// Creates an instance of the PowerAuth SDK client.
  ///
  /// Multiple PowerAuth SDK instances can be created, each identified by a unique [instanceId].
  /// The bundle identifier/packagename is recommended.
  ///
  /// Two instances with the same instanceId will be internally the same object!
  PowerAuth(this.instanceId): _tokenStore = PowerAuthTokenStore(instanceId),
        _timeSynchronizationService = PowerAuthTimeSynchronizationService(instanceId) {
    if (instanceId.isEmpty) {
      throw ArgumentError.value(instanceId, 'instanceId', 'cannot be empty');
    }
  }

  static PowerAuthPlatform get _platform => PowerAuthPlatform.instance;

  /// Returns the base configuration used for this instance, if configured.
  Future<PowerAuthConfiguration?> get configuration async => (await _getConfiguration(instanceId))?.configuration;

  /// Returns the client configuration used for this instance, if configured.
  Future<PowerAuthClientConfiguration?> get clientConfiguration async => (await _getConfiguration(instanceId))?.clientConfiguration;

  /// Returns the biometry configuration used for this instance, if configured.
  Future<PowerAuthBiometryConfiguration?> get biometryConfiguration async => (await _getConfiguration(instanceId))?.biometryConfiguration;

  /// Returns the keychain configuration used for this instance, if configured.
  Future<PowerAuthKeychainConfiguration?> get keychainConfiguration async => (await _getConfiguration(instanceId))?.keychainConfiguration;

  /// Returns the sharing configuration used for this instance (iOS only), if configured.
  Future<PowerAuthSharingConfiguration?> get sharingConfiguration async => (await _getConfiguration(instanceId))?.sharingConfiguration;

  /// Prepares the PowerAuth instance with an advanced configuration.
  ///
  /// Must be called before any other method.
  /// [configuration] - Configuration object with basic parameters for `PowerAuth` class.
  Future<void> configure({
    required PowerAuthConfiguration configuration,
    PowerAuthClientConfiguration? clientConfiguration,
    PowerAuthBiometryConfiguration? biometryConfiguration,
    PowerAuthKeychainConfiguration? keychainConfiguration,
    PowerAuthSharingConfiguration? sharingConfiguration
  }) async {
    // _configRegister[instanceId] = _InstanceConfigurationHolder(
    //   configuration: configuration,
    //   clientConfiguration: clientConfiguration,
    //   biometryConfiguration: biometryConfiguration,
    //   keychainConfiguration: keychainConfiguration,
    //   sharingConfiguration: sharingConfiguration
    // );

    await _platform.configure(
      instanceId: instanceId,
      configuration: configuration,
      clientConfiguration: clientConfiguration,
      biometryConfiguration: biometryConfiguration,
      keychainConfiguration: keychainConfiguration,
      sharingConfiguration: sharingConfiguration
    );
  }


  Future<PowerAuthInstanceConfigurationHolder?> _getConfiguration(String instanceId) async {
    // _platform.
    return _platform.getConfiguration(instanceId);
  }

  /// Checks if this instance is configured.
  Future<bool> isConfigured() => _platform.isConfigured(instanceId);

  /// Deconfigures this instance, removing its state.
  Future<void> deconfigure() async {
    await _platform.deconfigure(instanceId);
  }

  /// Checks if this instance has a valid activation.
  Future<bool> hasValidActivation() => _platform.hasValidActivation(instanceId);

  /// Checks if this instance can start a new activation process.
  Future<bool> canStartActivation() => _platform.canStartActivation(instanceId);

  /// Checks if this instance has an activation process already pending.
  Future<bool> hasPendingActivation() => _platform.hasPendingActivation(instanceId);

  /// Check if there's an external pending operation started in another application.
  Future<PowerAuthExternalPendingOperation?> getExternalPendingOperation() => _platform.getExternalPendingOperation(instanceId);

  /// Gets the current activation identifier for this instance, if activated.
  /// Returns `null` if no valid activation exists.
  Future<String?> getActivationIdentifier() => _platform.getActivationIdentifier(instanceId);

  /// Gets the fingerprint of the device's public key associated with the current activation.
  /// Returns `null` if no valid activation exists.
  Future<String?> getActivationFingerprint() => _platform.getActivationFingerprint(instanceId);

  /// Fetches the latest activation status from the PowerAuth server.
  /// This may involve network communication and potential protocol upgrades.
  Future<PowerAuthActivationStatus> fetchActivationStatus() => _platform.fetchActivationStatus(instanceId);

  /// Removes the activation state locally from the device.
  /// This does **not** inform the server. Use this only if the activation
  /// was removed externally (e.g., via web banking).
  Future<void> removeActivationLocal() => _platform.removeActivationLocal(instanceId);

  /// Removes the activation from both the local device and the PowerAuth server.
  /// Requires [authentication] to authorize the removal on the server.
  Future<void> removeActivationWithAuthentication(
    PowerAuthAuthentication authentication,
  ) => _platform.removeActivationWithAuthentication(instanceId, authentication);

  /// Starts the activation process using the provided [activation] details
  /// (activation code or custom attributes).
  ///
  /// Returns a [PowerAuthCreateActivationResult] containing the activation fingerprint.
  Future<PowerAuthCreateActivationResult> createActivation(PowerAuthActivation activation,) => _platform.createActivation(instanceId, activation);

  /// Persists the activation data locally after a successful `createActivation` call.
  ///
  /// Requires [authentication] (password and, optionally, biometry) to secure the local activation state.
  Future<void> persistActivation(PowerAuthAuthentication authentication) => _platform.persistActivation(instanceId, authentication);

  /// Validates the provided [password] against the server.
  /// This typically involves computing a signature and verifying it server-side.
  Future<void> validatePassword(PowerAuthPassword password) => _platform.validatePassword(instanceId, password);

  /// Changes the user's password. Validates the [oldPassword] on the server before
  /// setting the [newPassword].
  Future<void> changePassword(PowerAuthPassword oldPassword, PowerAuthPassword newPassword) => _platform.changePassword(instanceId, oldPassword, newPassword);

  /// Computes an HTTP signature header (`X-PowerAuth-Authorization`) for a GET request.
  ///
  /// - [authentication]: Specifies the factors to use for signing.
  /// - [uriId]: The URI identifier for the request path (e.g., "/api/user/detail").
  /// - [queryParams]: Optional query parameters to include in the signature calculation.
  Future<PowerAuthAuthorizationHttpHeader> requestGetSignature(
    PowerAuthAuthentication authentication,
    String uriId, [
    Map<String, String>? queryParams,
  ]) => _platform.requestGetSignature(
    instanceId,
    authentication,
    uriId,
    queryParams,
  );

  /// Computes an HTTP signature header (`X-PowerAuth-Authorization`) for a request with a body.
  ///
  /// - [authentication]: Specifies the factors to use for signing.
  /// - [method]: The HTTP method (e.g., "POST", "PUT").
  /// - [uriId]: The URI identifier for the request path (e.g., "/api/transfer").
  /// - [body]: Optional request body data (as a String) to include in the signature calculation.
  Future<PowerAuthAuthorizationHttpHeader> requestSignature(
    PowerAuthAuthentication authentication,
    String method,
    String uriId, [
    String? body,
  ]) => _platform.requestSignature(
    instanceId,
    authentication,
    method,
    uriId,
    body,
  );

  /// Computes an offline PowerAuth signature.
  /// This signature can be validated offline (e.g., on another device or by a backend).
  ///
  /// - [authentication]: Specifies the factors to use for signing (possession and knowledge recommended).
  /// - [uriId]: The URI identifier associated with the operation being signed.
  /// - [nonce]: A unique cryptographic nonce (Base64 encoded).
  /// - [body]: Optional data (as a String) included in the signature calculation.
  Future<String> offlineSignature(
    PowerAuthAuthentication authentication,
    String uriId,
    String nonce, [
    String? body,
  ]) => _platform.offlineSignature(
    instanceId,
    authentication,
    uriId,
    nonce,
    body,
  );

  /// Verifies data signed by the PowerAuth server's public key.
  ///
  /// - [data]: The original data that was signed (as a String).
  /// - [signature]: The Base64 encoded signature received from the server.
  /// - [useMasterKey]: If `true`, use the Master Server Public Key for verification.
  ///                   If `false`, use the current Personalized Server Public Key.
  Future<bool> verifyServerSignedData(
    String data,
    String signature,
    bool useMasterKey,
  ) => _platform.verifyServerSignedData(
    instanceId,
    data,
    signature,
    useMasterKey,
  );

  /// Gets information about the biometric capabilities of the device.
  static Future<PowerAuthBiometryInfo> getBiometryInfo() => _platform.getBiometryInfo();

  /// Adds or regenerates the biometry-related factor key locally.
  /// This typically requires vault unlock via the provided [password] ([PowerAuthPassword]).
  /// The optional [prompt] is used for the system biometric dialog if needed during key setup (Android specific).
  Future<void> addBiometryFactor(
    PowerAuthPassword password, [
    PowerAuthBiometricPrompt? prompt,
  ]) => _platform.addBiometryFactor(instanceId, password, prompt);

  /// Checks if a biometry key exists locally for the current activation.
  Future<bool> hasBiometryFactor() => _platform.hasBiometryFactor(instanceId);

  /// Removes the biometry key associated with the current activation locally.
  Future<void> removeBiometryFactor() => _platform.removeBiometryFactor(instanceId);

  /// Generate a derived encryption key with given index. The key is returned in form of base64 encoded string.
  /// 
  /// This method calls PowerAuth Standard RESTful API endpoint `/pa/vault/unlock` to obtain the vault encryption key used 
  /// for subsequent key derivation using given index.
  /// 
  /// - [authentication] Authentication used for vault unlocking call.
  /// - [index] Index of the derived key using KDF. 
  Future<String> fetchEncryptionKey(PowerAuthAuthentication authentication, int index) => _platform.fetchEncryptionKey(instanceId, authentication, index);

  /// Sign given data with the original device private key (asymetric signature).
  /// 
  /// This method calls PowerAuth Standard RESTful API endpoint `/pa/vault/unlock` to obtain the vault encryption key 
  /// used for private key decryption. Data is then signed using ECDSA algorithm with this key and can be validated on the server side.
  /// 
  /// - [authentication] Authentication used for vault unlocking call.
  /// - [data] Data to be signed with the private key.
  /// - [dataFormat] Specifies format of passed data. If not used, then [PowerAuthDataFormat.utf8] is applied.
  Future<String> signDataWithDevicePrivateKey(PowerAuthAuthentication authentication, String data, {PowerAuthDataFormat dataFormat = PowerAuthDataFormat.utf8}) 
  => _platform.signDataWithDevicePrivateKey(instanceId, authentication, data, dataFormat);

  /// Helper method for grouping biometric authentications.
  /// 
  /// With this method, you can use 1 biometric authentication (dialog) for several operations.
  /// Just use the `PowerAuthAuthentication` variable inside the `groupedAuthenticationCalls` callback.
  /// 
  /// Be aware, that you must not execute the next HTTP request signed with the same credentials when the previous one 
  /// fails with the 401 HTTP status code. If you do, then you risk blocking the user's activation on the server.
  /// 
  /// - [authentication] authentication object
  /// - [groupedAuthenticationCalls] call that will use reusable authentication object
  Future<void> groupedBiometricAuthentication(
    PowerAuthAuthentication authentication, 
    Future<void> Function(PowerAuthAuthentication) groupedAuthenticationCalls) async {
      if (!await isConfigured()) {
        throw PowerAuthException(code: PowerAuthErrorCode.instanceNotConfigured, message: "Instance is not configured");
      }
      final reusable = (await _platform.resolveAuthentication(instanceId, authentication, makeReusable: true)) as InternalAuth;
      if (reusable.useBiometry == false) {
        throw PowerAuthException(code: PowerAuthErrorCode.wrongParameter, message: "Authentication object is not configured for biometric factor");
      }
      try {
        // integrator defined chain of authorization calls with reusable authentication
        await groupedAuthenticationCalls(reusable);
      } catch (e) {
        // rethrow the error with information that the integrator should handle errors by himself
        throw PowerAuthException(code: PowerAuthErrorCode.unknownError, message: "Your 'groupedAuthenticationCalls' function threw an exception. Please make sure that you catch errors yourself.");
      }  
  }

  /// Returns an encryptor for application scope.
  ///
  /// The encryptor is reusable and can be used to encrypt multiple requests.
  /// Encryption is available without activation.
  PowerAuthEncryptor getEncryptorForApplicationScope() {
    return PowerAuthRequestEncryptor(
      encryptorScope: PowerAuthEncryptorScope.application,
      powerAuthInstanceId: instanceId,
    );
  }

  /// Returns an encryptor for activation scope.
  ///
  /// The encryptor is reusable and can be used to encrypt multiple requests.
  /// Encryption requires valid activation.
  PowerAuthEncryptor getEncryptorForActivationScope() {
    return PowerAuthRequestEncryptor(
      encryptorScope: PowerAuthEncryptorScope.activation,
      powerAuthInstanceId: instanceId,
    );
  }

  /// Fetch information about the user from the server. If the operation succeeds, then the user
  /// information object is also internally stored and available in [getLastFetchedUserInfo] method.
  Future<PowerAuthUserInfo> fetchUserInfo() {
    return _platform.fetchUserInfo(instanceId);
  }

  /// Returns the last fetched information about the user. The information about the user is optional and 
  /// must be supported by the server. The value is updated during the activation process or by 
  /// calling [fetchUserInfo].
  /// 
  /// Note that the user info is not cached between app launches.
  Future<PowerAuthUserInfo?> getLastFetchedUserInfo() {
    return _platform.getLastFetchedUserInfo(instanceId);
  }
}
