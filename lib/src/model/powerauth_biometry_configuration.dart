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

import 'dart:io' show Platform;

/// Contains configuration for biometry-related features.
class PowerAuthBiometryConfiguration {
  /// Set whether the key protected with the biometry is invalidated if fingers are added or
  /// removed, or if the user re-enrolls for face. The default value depends on platform:
  /// - On Android is set to `true`
  /// - On iOS is set to `false`
  final bool invalidateBiometricFactorAfterChange;

  /// ### iOS specific
  ///
  /// If set to `true`, then the key protected with the biometry can be accessed also with a device passcode.
  /// If set, then `invalidateBiometricFactorAfterChange` option has no effect. The default is `false`, so fallback
  /// to device's passcode is not enabled.
  final bool fallbackToDevicePasscode;

  /// ### Android specific
  ///
  /// If set to `true`, then the user's confirmation will be required after the successful biometric authentication.
  /// Defaults to `false`.
  final bool confirmBiometricAuthentication;

  /// ### Android specific
  ///
  /// Set, whether biometric key setup always require a biometric authentication.
  ///
  /// ### Discussion
  ///
  /// Setting parameter to `true` leads to use symmetric HMAC-KDF on the background,
  /// so both configuration and usage of biometric key require the biometric authentication.
  ///
  /// If set to `false`, then RSA cipher is used and only the usage of biometric key
  /// require the biometric authentication. This is due to fact, that RSA cipher can encrypt
  /// data using its public key available immediately after the key-pair is created in
  /// Android KeyStore.
  ///
  /// The default value is `true`.
  final bool authenticateOnBiometricKeySetup;

  /// ### Android specific
  ///
  /// Set whether fallback to a shared, legacy biometry key is enabled. By default, this is enabled for compatibility
  /// reasons. If enabled, `PowerAuth` performs an additional lookup for a legacy biometric key previously shared
  /// between multiple `PowerAuth` object instances.
  ///
  /// If your application uses multiple `PowerAuth` instances, it's recommended to set this configuration to `false`.
  /// This is because the native SDK doesn't properly handle multiple activations with the shared biometric key.
  ///
  /// If set to `false`, the shared key will no longer be accessible, and you may need to reconfigure the biometric factor
  /// for the existing activations on your `PowerAuth` object instances.
  ///
  /// The default value is `true`, so the fallback is enabled.
  final bool fallbackToSharedBiometryKey;

  /// ### Android specific
  ///
  /// If `true`, the SDK uses the legacy AES-KDF biometric key protection from
  /// PowerAuth Mobile SDK 1.x instead of HMAC-KDF. This option is intended only
  /// for testing. The default value is `false`.
  final bool useLegacySymmetricKey;

  PowerAuthBiometryConfiguration({
    bool? invalidateBiometricFactorAfterChange,
    this.fallbackToDevicePasscode = false,
    this.confirmBiometricAuthentication = false,
    this.authenticateOnBiometricKeySetup = true,
    this.fallbackToSharedBiometryKey = true,
    this.useLegacySymmetricKey = false,
  }) : invalidateBiometricFactorAfterChange = invalidateBiometricFactorAfterChange ?? Platform.isAndroid;

  Map<String, dynamic> toMap() {
    return {
      'invalidateBiometricFactorAfterChange': invalidateBiometricFactorAfterChange,
      'fallbackToDevicePasscode': fallbackToDevicePasscode,
      'confirmBiometricAuthentication': confirmBiometricAuthentication,
      'authenticateOnBiometricKeySetup': authenticateOnBiometricKeySetup,
      'fallbackToSharedBiometryKey': fallbackToSharedBiometryKey,
      'useLegacySymmetricKey': useLegacySymmetricKey,
    };
  }

  factory PowerAuthBiometryConfiguration.fromMap(Map<String, dynamic> map) {
    return PowerAuthBiometryConfiguration(
      invalidateBiometricFactorAfterChange: map['invalidateBiometricFactorAfterChange'] as bool,
      fallbackToDevicePasscode: map['fallbackToDevicePasscode'] as bool,
      confirmBiometricAuthentication: map['confirmBiometricAuthentication'] as bool,
      authenticateOnBiometricKeySetup: map['authenticateOnBiometricKeySetup'] as bool,
      fallbackToSharedBiometryKey: map['fallbackToSharedBiometryKey'] as bool,
      useLegacySymmetricKey: map['useLegacySymmetricKey'] as bool? ?? false,
    );
  }
}
