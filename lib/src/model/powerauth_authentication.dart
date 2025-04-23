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

import '../powerauth_password/powerauth_password.dart';

/// Defines strings used to display the platform-specific biometric authentication dialog.
class PowerAuthBiometricPrompt {

  /// Prompt message displayed to the user.
  /// Example: "Please authorize the payment with the biometric sensor"
  final String promptMessage;

  /// ### Android specific
  /// Title displayed to the user.
  /// Example: "Payment authorization"
  final String? promptTitle;

  /// ### iOS specific
  /// Title for the cancel button.
  final String? cancelButtonTitle;

  /// ### iOS specific
  /// Title for the fallback button (e.g., "Enter Password").
  /// If set, allows falling back from biometrics.
  final String? fallbackButtonTitle;

  PowerAuthBiometricPrompt({
    required this.promptMessage,
    this.promptTitle, // Required on Android
    this.cancelButtonTitle,
    this.fallbackButtonTitle,
  });

  Map<String, dynamic> toMap() {
    return {
      'promptMessage': promptMessage,
      'promptTitle': promptTitle,
      'cancelButtonTitle': cancelButtonTitle,
      'fallbackButtonTitle': fallbackButtonTitle,
    }..removeWhere((key, value) => value == null);
  }
}

/// Represents a multi-factor authentication object specifying which factors to use for an operation.
/// Use the factory constructors to create instances for different factor combinations.
class PowerAuthAuthentication {

  /// Password used for the knowledge factor. Can be a [String] or [PowerAuthPassword].
  /// Set only if the knowledge factor is required.
  final Object? password;

  /// Configuration for the biometric prompt, if biometry factor is used.
  final PowerAuthBiometricPrompt? biometricPrompt;

  /// Indicates that this authentication object is intended for persisting an activation.
  final bool forActivationPersist;

  /// Indicates if the biometry factor should be used.
  final bool useBiometry;

  // Internal constructor
  PowerAuthAuthentication._({
    this.password,
    this.biometricPrompt,
    required this.forActivationPersist,
    required this.useBiometry,
  });

  /// Creates an authentication object configured for possession factor only.
  factory PowerAuthAuthentication.possession() {
    return PowerAuthAuthentication._(
      forActivationPersist: false,
      useBiometry: false,
    );
  }

  /// Creates an authentication object configured for possession and biometry factors.
  factory PowerAuthAuthentication.biometry({
    required PowerAuthBiometricPrompt biometricPrompt,
  }) {
    return PowerAuthAuthentication._(
      biometricPrompt: biometricPrompt,
      forActivationPersist: false,
      useBiometry: true,
    );
  }

  /// Creates an authentication object configured for possession and knowledge (password) factors.
  /// [password] can be a [String] or a [PowerAuthPassword] object.
  factory PowerAuthAuthentication.password(Object password) {
    validatePasswordType(password);
    return PowerAuthAuthentication._(
      password: password,
      forActivationPersist: false,
      useBiometry: false,
    );
  }

  /// Creates an object configured to persist activation with password.
  /// [password] can be a [String] or a [PowerAuthPassword] object.
  factory PowerAuthAuthentication.persistWithPassword(Object password) {
    validatePasswordType(password);
    return PowerAuthAuthentication._(
      password: password,
      forActivationPersist: true,
      useBiometry: false,
    );
  }

  /// Creates an object configured to persist activation with password and biometry.
  /// [password] can be a [String] or a [PowerAuthPassword] object.
  /// [biometricPrompt] is required on Android only when biometry config has `authenticateOnBiometricKeySetup` set to `true`.
  factory PowerAuthAuthentication.persistWithPasswordAndBiometry({
    required Object password,
    PowerAuthBiometricPrompt? biometricPrompt,
  }) {
    validatePasswordType(password);
    return PowerAuthAuthentication._(
      password: password,
      biometricPrompt: biometricPrompt,
      forActivationPersist: true,
      useBiometry: true,
    );
  }

  // Helper to validate password type
  static void validatePasswordType(Object password) {
    if (password is! String && password is! PowerAuthPassword) {
      throw ArgumentError(
        'Password must be a String or a PowerAuthPassword object.',
      );
    }
  }

  /// Converts this object into a map suitable for sending over the method channel.
  /// Handles converting PowerAuthPassword to its raw representation.
  Future<Map<String, dynamic>> toMap() async {
    Object? rawPassword;
    if (password is PowerAuthPassword) {
      rawPassword = await (password as PowerAuthPassword).toRawPasswordMap();
    } else if (password is String) {
      rawPassword = password;
    }

    return {
      'password': rawPassword,
      'biometricPrompt': biometricPrompt?.toMap(),
      'isPersist': forActivationPersist,
      'isBiometry': useBiometry,
      // 'isReusable' and 'biometryKeyId' seem internal to the RN layer for optimization, might not be needed directly here.
    }..removeWhere((key, value) => value == null);
  }
}
