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

import 'powerauth_platform_interface.dart';

import '../model/powerauth_activation.dart';
import '../model/powerauth_activation_status.dart';
import '../model/powerauth_authentication.dart';
import '../model/powerauth_authorization_http_header.dart';
import '../model/powerauth_configuration.dart';
import '../model/powerauth_create_activation_result.dart';
import '../powerauth_password/powerauth_password.dart';

/// Internal helper class to hold the configuration set for a single PowerAuth instance.
class _InstanceConfigurationHolder {
  final PowerAuthConfiguration configuration;

  _InstanceConfigurationHolder({
    required this.configuration
  });
}

/// Main class for interacting with the PowerAuth Mobile SDK.
///
/// Use this class to manage activation, authentication, signatures, and other core features.
class PowerAuth {

  final String instanceId;

  // Static registry to hold configurations for active instances
  static final Map<String, _InstanceConfigurationHolder> _configRegister = {};

  /// Creates an instance of the PowerAuth SDK client.
  ///
  /// Multiple PowerAuth SDK instances can be created, each identified by a unique [instanceId].
  ///  The bundle identifier/packagename is recommended.
  /// 
  /// 2 instances with the same instanceId will be internaly the same object!
  PowerAuth(this.instanceId);

  static PowerAuthPlatform get _platform => PowerAuthPlatform.instance;


  /// Returns the base configuration used for this instance, if configured.
  PowerAuthConfiguration? get configuration =>
      _configRegister[instanceId]?.configuration;

  /// Prepares the PowerAuth instance with an advanced configuration.
  /// 
  /// Must be called before any other method.
  /// [configuration] - Configuration object with basic parameters for `PowerAuth` class.
  Future<void> configure({
    required PowerAuthConfiguration configuration
  }) async {
    _configRegister[instanceId] = _InstanceConfigurationHolder(
      configuration:
          configuration
    );

    await _platform.configure(
      instanceId: instanceId,
      configuration: configuration
    );
  }

  /// Checks if this instance is configured.
  Future<bool> isConfigured() => _platform.isConfigured(instanceId);

  /// Deconfigures this instance, removing its state.
  void deconfigure() async {
    _configRegister.remove(instanceId);
    await _platform.deconfigure(instanceId);
  }

  /// Checks if this instance has a valid activation.
  Future<bool> hasValidActivation() => _platform.hasValidActivation(instanceId);

  /// Checks if this instance can start a new activation process.
  Future<bool> canStartActivation() => _platform.canStartActivation(instanceId);

  /// Checks if this instance has an activation process already pending.
  Future<bool> hasPendingActivation() =>
      _platform.hasPendingActivation(instanceId);

  /// Gets the current activation identifier for this instance, if activated.
  /// Returns `null` if no valid activation exists.
  Future<String?> getActivationIdentifier() =>
      _platform.getActivationIdentifier(instanceId);

  /// Gets the fingerprint of the device's public key associated with the current activation.
  /// Returns `null` if no valid activation exists.
  Future<String?> getActivationFingerprint() =>
      _platform.getActivationFingerprint(instanceId);

  /// Fetches the latest activation status from the PowerAuth server.
  /// This may involve network communication and potential protocol upgrades.
  Future<PowerAuthActivationStatus> fetchActivationStatus() =>
      _platform.fetchActivationStatus(instanceId);

  /// Removes the activation state locally from the device.
  /// This does **not** inform the server. Use this only if the activation
  /// was removed externally (e.g., via web banking).
  Future<void> removeActivationLocal() =>
      _platform.removeActivationLocal(instanceId);

  /// Removes the activation from both the local device and the PowerAuth server.
  /// Requires [authentication] to authorize the removal on the server.
  Future<void> removeActivationWithAuthentication(
    PowerAuthAuthentication authentication,
  ) => _platform.removeActivationWithAuthentication(instanceId, authentication);

  /// Starts the activation process using the provided [activation] details
  /// (activation code, recovery code, or custom attributes).
  /// 
  /// Returns a [PowerAuthCreateActivationResult] containing the activation fingerprint
  /// and potentially recovery information.
  Future<PowerAuthCreateActivationResult> createActivation(
    PowerAuthActivation activation,
  ) => _platform.createActivation(instanceId, activation);

  /// Persists the activation data locally after a successful `createActivation` call.
  /// 
  /// Requires [authentication] (password and optionally biometry) to secure the local activation state.
  Future<void> persistActivation(PowerAuthAuthentication authentication) =>
      _platform.persistActivation(instanceId, authentication);

  /// Validates the provided [password] against the server.
  /// This typically involves computing a signature and verifying it server-side.
  Future<void> validatePassword(PowerAuthPassword password) =>
      _platform.validatePassword(instanceId, password);

  /// Changes the user's password. Validates the [oldPassword] on the server before
  /// setting the [newPassword].
  Future<void> changePassword(PowerAuthPassword oldPassword, PowerAuthPassword newPassword) =>
      _platform.changePassword(instanceId, oldPassword, newPassword);

  /// Changes the user's password locally without server-side validation of the [oldPassword].
  /// 
  /// **Warning:** Use with extreme caution. If the [oldPassword] is incorrect,
  /// the local activation state may become corrupted. Ensure the old password
  /// is validated through other means before calling this.
  /// 
  /// Returns `true` if the local change was successful, `false` otherwise (e.g., cryptographic error).
  Future<bool> unsafeChangePassword(PowerAuthPassword oldPassword, PowerAuthPassword newPassword) =>
      _platform.unsafeChangePassword(instanceId, oldPassword, newPassword);

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

  // TODO: this is ready, but biometry is planned for phase 1.5
  // /// Gets information about the biometric capabilities of the device.
  // Future<PowerAuthBiometryInfo> getBiometryInfo() =>
  //     _platform.getBiometryInfo(instanceId);

  // /// Adds or regenerates the biometry-related factor key locally.
  // /// This typically requires vault unlock via the provided [password] ([String] or [PowerAuthPassword]).
  // /// The optional [prompt] is used for the system biometric dialog if needed during key setup (Android specific).
  // Future<void> addBiometryFactor(
  //   Object password, [
  //   PowerAuthBiometricPrompt? prompt,
  // ]) => _platform.addBiometryFactor(instanceId, password, prompt);

  // /// Checks if a biometry key exists locally for the current activation.
  // Future<bool> hasBiometryFactor() => _platform.hasBiometryFactor(instanceId);

  // /// Removes the biometry key associated with the current activation locally.
  // Future<void> removeBiometryFactor() =>
  //     _platform.removeBiometryFactor(instanceId);

  // TODO: remove this debug call before release!
  // --- DEBUG ---
  Future<String?> getPlatformVersion() => _platform.getPlatformVersion();
}
