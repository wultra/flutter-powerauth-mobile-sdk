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
import 'dart:typed_data';

import '../model/powerauth_biometric_status.dart';
import '../model/powerauth_biometry_configuration.dart';
import '../model/powerauth_client_configuration.dart';
import '../model/powerauth_keychain_configuration.dart';
import '../model/powerauth_sharing_configuration.dart';
import '../model/powerauth_user_info.dart';
import 'powerauth_platform_interface.dart';

import '../model/powerauth_activation.dart';
import '../model/powerauth_activation_status.dart';
import '../model/powerauth_authentication.dart';
import '../model/powerauth_http_header.dart';
import '../model/powerauth_algorithm.dart';
import '../model/powerauth_configuration.dart';
import '../powerauth_password/powerauth_password.dart';
import '../model/powerauth_encryptor.dart';
import '../model/powerauth_external_pending_operation.dart';
import '../powerauth_encryptor/powerauth_encryptor.dart';
import 'powerauth_token_store.dart';
import 'powerauth_time_synchronization_service.dart';
import '../model/powerauth_create_activation_result.dart';
import '../model/powerauth_error.dart';
import '../model/powerauth_authentication_internal.dart';
import '../model/powerauth_signature_key_id.dart';
import '../model/powerauth_device_public_key.dart';
import '../model/powerauth_secure_vault_key.dart';
import '../model/powerauth_protocol_upgrade_result.dart';
import '../model/powerauth_password_change_data.dart';

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
  Future<PowerAuthConfiguration> get configuration async => (await _platform.getConfiguration(instanceId));

  /// Returns the algorithm currently used for communication with the PowerAuth Server.
  Future<PowerAuthAlgorithm> get currentAlgorithm async => (await _platform.getCurrentAlgorithm(instanceId));

  // TODO: Uncomment when the SDK provides access to these configurations in SDK version 2.0.0 or later.

  // /// Returns the client configuration used for this instance, if configured.
  // Future<PowerAuthClientConfiguration?> get clientConfiguration async => (await _platform.getClientConfiguration(instanceId));

  // /// Returns the biometry configuration used for this instance, if configured.
  // Future<PowerAuthBiometryConfiguration?> get biometryConfiguration async => (await _platform.getBiometryConfiguration(instanceId));

  // /// Returns the keychain configuration used for this instance, if configured.
  // Future<PowerAuthKeychainConfiguration?> get keychainConfiguration async => (await _platform.getKeychainConfiguration(instanceId));

  // /// Returns the sharing configuration used for this instance (iOS only), if configured.
  // Future<PowerAuthSharingConfiguration?> get sharingConfiguration async => (await _platform.getSharingConfiguration(instanceId));

  /// Prepares the PowerAuth instance with an advanced configuration.
  ///
  /// Must be called before any other method.
  /// [configuration] - Configuration object with basic parameters for `PowerAuth` class.
  /// [keychainConfiguration] - Android-only secure-storage configuration.
  /// [sharingConfiguration] - iOS-only activation-sharing configuration.
  Future<void> configure({
    required PowerAuthConfiguration configuration,
    PowerAuthClientConfiguration? clientConfiguration,
    PowerAuthBiometryConfiguration? biometryConfiguration,
    PowerAuthKeychainConfiguration? keychainConfiguration,
    PowerAuthSharingConfiguration? sharingConfiguration,
  }) async {
    await _platform.configure(
      instanceId: instanceId,
      configuration: configuration,
      clientConfiguration: clientConfiguration,
      biometryConfiguration: biometryConfiguration,
      keychainConfiguration: keychainConfiguration,
      sharingConfiguration: sharingConfiguration,
    );
  }

  /// Removes incompatible local data after instance configuration fails.
  ///
  /// Use the same [instanceId], [configuration], and [keychainConfiguration]
  /// that were used to configure the instance.
  static Future<void> cleanupInstanceData({
    required String instanceId,
    required PowerAuthConfiguration configuration,
    PowerAuthKeychainConfiguration? keychainConfiguration,
    PowerAuthSharingConfiguration? sharingConfiguration,
  }) => _platform.cleanupInstanceData(
    instanceId: instanceId,
    configuration: configuration,
    keychainConfiguration: keychainConfiguration,
    sharingConfiguration: sharingConfiguration,
  );

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

  /// Returns `true` if a protocol upgrade is available for the current activation.
  ///
  /// The result reflects locally stored activation status. Call
  /// [fetchActivationStatus] first to obtain the latest information from the
  /// PowerAuth server.
  Future<bool> hasProtocolUpgradeAvailable() => _platform.hasProtocolUpgradeAvailable(instanceId);

  /// Returns `true` if a protocol upgrade has started but has not yet finished.
  Future<bool> hasPendingProtocolUpgrade() => _platform.hasPendingProtocolUpgrade(instanceId);

  /// Starts a protocol upgrade for the current activation.
  ///
  /// The [password] is required to authorize the upgrade. Set
  /// [upgradeBiometry] to `true` to migrate an existing local biometry factor.
  /// Biometry migration is supported only when `authenticateOnBiometricKeySetup`
  /// is disabled. Otherwise, use the default value and add the biometry factor
  /// again after the upgrade if it was removed.
  ///
  /// If the returned result has `activationStatusFetchRequired` set to `true`,
  /// call [fetchActivationStatus] to finish the upgrade.
  Future<PowerAuthProtocolUpgradeResult> startProtocolUpgrade(
    PowerAuthPassword password, {
    bool upgradeBiometry = false,
  }) => _platform.startProtocolUpgrade(
    instanceId,
    password,
    upgradeBiometry: upgradeBiometry,
  );

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

  /// Begins a password change by validating the [oldPassword] on the server.
  ///
  /// Call [PowerAuthPasswordChangeData.release] if the operation is abandoned.
  Future<PowerAuthPasswordChangeData> beginPasswordChange(PowerAuthPassword oldPassword) async {
    final objectId = await _platform.beginPasswordChange(instanceId, oldPassword);
    return PowerAuthPasswordChangeData.fromNative(
      objectId: objectId,
    );
  }

  /// Finishes a password change initiated by [beginPasswordChange].
  ///
  /// The [passwordChangeData] object is consumed and released by this call,
  /// regardless of whether the operation succeeds or fails.
  Future<void> finishPasswordChange(
    PowerAuthPassword newPassword,
    PowerAuthPasswordChangeData passwordChangeData,
  ) async {
    await passwordChangeData.executeAndRelease(
      (objectId) => _platform.finishPasswordChange(instanceId, newPassword, objectId),
    );
  }

  /// Computes an HTTP authentication header for a request with query parameters.
  ///
  /// - [authentication]: Specifies the factors to use for signing.
  /// - [method]: The HTTP method (for example, `"GET"`).
  /// - [uriId]: The URI identifier for the request path (e.g., "/api/user/detail").
  /// - [params]: Optional query parameters to include in the authentication calculation.
  Future<PowerAuthHttpHeader> authenticationHeaderForRequestWithParams(
    PowerAuthAuthentication authentication,
    String method,
    String uriId, [
    Map<String, String>? params,
  ]) => _platform.authenticationHeaderForRequestWithParams(
    instanceId,
    authentication,
    method,
    uriId,
    params,
  );

  /// Computes an HTTP authentication header for a request with a body.
  ///
  /// - [authentication]: Specifies the factors to use for signing.
  /// - [method]: The HTTP method (e.g., "POST", "PUT").
  /// - [uriId]: The URI identifier for the request path (e.g., "/api/transfer").
  /// - [body]: Optional raw request body data to include in the authentication calculation.
  Future<PowerAuthHttpHeader> authenticationHeaderForRequestWithBody(
    PowerAuthAuthentication authentication,
    String method,
    String uriId, [
    Uint8List? body,
  ]) => _platform.authenticationHeaderForRequestWithBody(
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
  /// - [body]: Optional raw data included in the signature calculation.
  Future<String> offlineSignature(
    PowerAuthAuthentication authentication,
    String uriId,
    String nonce, [
    Uint8List? body,
  ]) => _platform.offlineSignature(
    instanceId,
    authentication,
    uriId,
    nonce,
    body,
  );

  /// Verifies a digital [signature] for the supplied raw [data].
  ///
  /// The [signatureKeyId] must identify a specific verification key. If the
  /// signature is invalid, a [PowerAuthException] with
  /// [PowerAuthErrorCode.wrongSignature] is thrown.
  Future<void> verifyDigitalSignature(
    Uint8List signature,
    Uint8List data,
    PowerAuthSignatureKeyId signatureKeyId,
  ) => _platform.verifyDigitalSignature(
    instanceId,
    signature,
    data,
    signatureKeyId,
  );

  /// Calculates a digital signature for the supplied raw [data] and returns it as raw bytes.
  ///
  /// The [signatureKeyId] must identify a specific device signing key, such as
  /// [PowerAuthSignatureKeyId.deviceEc] or [PowerAuthSignatureKeyId.deviceMlDsa].
  Future<Uint8List> calculateDigitalSignature(
    PowerAuthAuthentication authentication,
    Uint8List data,
    PowerAuthSignatureKeyId signatureKeyId,
  ) => _platform.calculateDigitalSignature(
    instanceId,
    authentication,
    data,
    signatureKeyId,
  );

  /// Exports device public keys in the requested [format].
  Future<List<PowerAuthDevicePublicKeyData>> exportDevicePublicKeys(
    PowerAuthDevicePublicKeyFormat format,
  ) => _platform.exportDevicePublicKeys(instanceId, format);

  /// Verifies JWS or JWT signed data using the specified key.
  ///
  /// If [compact] is `true`, [signature] is expected to be a compact JWT.
  /// Otherwise, a full JWS object is expected. If [strict] is `true`, all
  /// selected keys must successfully verify their corresponding signatures.
  /// If verification fails, a [PowerAuthException] is thrown.
  Future<void> verifyJwsSignature(
    String signature,
    bool compact,
    bool strict,
    PowerAuthSignatureKeyId signatureKeyId,
  ) => _platform.verifyJwsSignature(
    instanceId,
    signature,
    compact,
    strict,
    signatureKeyId,
  );

  /// Calculates a JWS signature for the supplied raw [data].
  ///
  /// The optional [dataType] is added to the protected JOSE header as `typ`.
  /// If [compact] is `true`, the result is a compact JWT. Otherwise, a full
  /// JWS object is returned.
  Future<String> calculateJwsSignature(
    PowerAuthAuthentication authentication,
    Uint8List data,
    String? dataType,
    bool compact,
    PowerAuthSignatureKeyId signatureKeyId,
  ) => _platform.calculateJwsSignature(
    instanceId,
    authentication,
    data,
    dataType,
    compact,
    signatureKeyId,
  );

  /// Creates an X.509 Certificate Signing Request in PEM format.
  ///
  /// The request contains the supplied [distinguishedNames], optional
  /// [subjectAltNames], and the public key identified by [signatureKeyId]. It
  /// is signed with the corresponding device private key.
  Future<String> createCertificateSigningRequest(
    PowerAuthAuthentication authentication,
    Map<String, String> distinguishedNames,
    List<String>? subjectAltNames,
    PowerAuthSignatureKeyId signatureKeyId,
  ) => _platform.createCertificateSigningRequest(
    instanceId,
    authentication,
    distinguishedNames,
    subjectAltNames,
    signatureKeyId,
  );

  /// Adds or regenerates the biometry-related factor key locally.
  /// This typically requires vault unlock via the provided [password] ([PowerAuthPassword]).
  /// The optional [prompt] is used for the system biometric dialog if needed during key setup (Android specific).
  Future<void> addBiometryFactor(
    PowerAuthPassword password, [
    PowerAuthBiometricPrompt? prompt,
  ]) => _platform.addBiometryFactor(instanceId, password, prompt);

  /// Checks if a biometry key exists locally for the current activation.
  Future<bool> hasBiometryFactor() => _platform.hasBiometryFactor(instanceId);

  /// Gets the biometric authentication status for the current activation.
  Future<PowerAuthBiometricStatus> getBiometricStatus() => _platform.getBiometricStatus(instanceId);

  /// Checks whether biometric authentication is available for the current activation.
  Future<bool> isAuthenticationWithBiometricsAvailable() => _platform.isAuthenticationWithBiometricsAvailable(instanceId);

  /// Removes the biometry key associated with the current activation locally.
  Future<void> removeBiometryFactor() => _platform.removeBiometryFactor(instanceId);

  /// Generate a derived encryption key with given index. The key is returned as raw bytes.
  /// 
  /// This method calls PowerAuth Standard RESTful API endpoint `/pa/vault/unlock` to obtain the vault encryption key used 
  /// for subsequent key derivation using given index.
  /// 
  /// - [authentication] Authentication used for vault unlocking call.
  /// - [index] Index of the derived key using KDF. 
  @Deprecated('Legacy protocol 3.3 only. Migrate the activation and use fetchSecureVaultKey() with protocol 4.0.')
  Future<Uint8List> fetchEncryptionKey(PowerAuthAuthentication authentication, int index) => _platform.fetchEncryptionKey(instanceId, authentication, index);

  /// Fetches a base Secure Vault key for subsequent key derivation.
  ///
  /// This method is available only for activations using PowerAuth protocol 4.0.
  /// The returned object keeps the base key on the native side and must be
  /// released as soon as all required keys have been derived.
  ///
  /// - [authentication] Authentication used for the vault unlocking call.
  /// - [keyIdentifier] Secure Vault key to retrieve.
  Future<PowerAuthSecureVaultKey> fetchSecureVaultKey(
    PowerAuthAuthentication authentication,
    PowerAuthSecureVaultKeyId keyIdentifier,
  ) async {
    final objectId = await _platform.fetchSecureVaultKey(
      instanceId,
      authentication,
      keyIdentifier.name,
    );
    return PowerAuthSecureVaultKey.fromNative(
      keyIdentifier: keyIdentifier,
      objectId: objectId,
    );
  }

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

  /// Acquires a single-use encryptor for application scope.
  ///
  /// Encryption is available without activation. Acquire a new encryptor for
  /// every request and response exchange and release it in a `finally` block.
  Future<PowerAuthEncryptor> getEncryptorForApplicationScope() {
    return PowerAuthEncryptorImpl.acquire(
      scope: PowerAuthEncryptorScope.application,
      powerAuthInstanceId: instanceId,
    );
  }

  /// Acquires a single-use encryptor for activation scope.
  ///
  /// A valid activation is required at acquisition time. Acquire a new
  /// encryptor for every request and response exchange and release it in a
  /// `finally` block.
  Future<PowerAuthEncryptor> getEncryptorForActivationScope() {
    return PowerAuthEncryptorImpl.acquire(
      scope: PowerAuthEncryptorScope.activation,
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
