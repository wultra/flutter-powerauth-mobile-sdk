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

import 'package:flutter_powerauth_mobile_sdk_plugin/src/model/powerauth_authentication_internal.dart';
import 'package:meta/meta.dart';

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
abstract class PowerAuthAuthentication {

  /// Password used for the knowledge factor.
  /// Set only if the knowledge factor is required.
  abstract final PowerAuthPassword? password;

  /// Configuration for the biometric prompt, if biometry factor is used.
  abstract final PowerAuthBiometricPrompt? biometricPrompt;

  /// Creates an authentication object configured for possession factor only.
  factory PowerAuthAuthentication.possession() {
    return InternalAuth(
      forActivationPersist: false
    );
  }

  /// Creates an authentication object configured for possession and biometry factors.
  factory PowerAuthAuthentication.biometry({required PowerAuthBiometricPrompt biometricPrompt}) {
    return InternalAuth(
      biometricPrompt: biometricPrompt,
      forActivationPersist: false
    );
  }

  /// Creates an authentication object configured for possession and knowledge (password) factors.
  factory PowerAuthAuthentication.password(PowerAuthPassword password) {
    return InternalAuth(
      password: password,
      forActivationPersist: false
    );
  }

  /// Creates an object configured to persist activation with password.
  factory PowerAuthAuthentication.persistWithPassword(PowerAuthPassword password) {
    return InternalAuth(
      password: password,
      forActivationPersist: true
    );
  }

  /// Creates an object configured to persist activation with password and biometry.
  /// [password] [PowerAuthPassword] object.
  /// [biometricPrompt] is required on Android only when biometry config has `authenticateOnBiometricKeySetup` set to `true`.
  factory PowerAuthAuthentication.persistWithPasswordAndBiometry({
    required PowerAuthPassword password,
    required PowerAuthBiometricPrompt biometricPrompt,
  }) {
    return InternalAuth(
      password: password,
      biometricPrompt: biometricPrompt,
      forActivationPersist: true,
    );
  }

  /// Helper to prepare authentication arguments.
  Future<Map<String, dynamic>> prepareAuthArguments(Map<String, dynamic> baseArgs);
}
