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

/// Contains activation data required for the activation creation.
/// Use one of the factory constructors to create an instance based on the activation type.
class PowerAuthActivation {

  /// Activation name to be assigned to new activation. Recommended to set to device name.
  final String activationName;

  /// Activation code, obtained either via QR code scanning or by manual entry.
  /// May contain an optional signature part if scanned from a QR code.
  final String? activationCode;

  /// Recovery code, obtained either via QR code scanning or by manual entry.
  final String? recoveryCode;

  /// PUK obtained by manual entry.
  final String? recoveryPuk;

  /// Custom activation parameters that are used to prove identity of a user.
  final Map<String, dynamic>? identityAttributes;

  /// Extra attributes of the activation, used for application specific purposes
  /// (e.g., info about the client device or system).
  /// This string will be associated with the activation record on PowerAuth Server.
  final String? extras;

  /// Custom attributes object that are processed on Intermediate Server Application.
  /// Note that this custom data will *not* be associated with the activation record on PowerAuth Server.
  final Map<String, dynamic>? customAttributes;

  /// Additional activation OTP that can be used only with a regular activation (by activation code).
  final String? additionalActivationOtp;

  // Private constructor to enforce factory usage
  PowerAuthActivation._({
    required this.activationName,
    this.activationCode,
    this.recoveryCode,
    this.recoveryPuk,
    this.identityAttributes,
    this.extras,
    this.customAttributes,
    this.additionalActivationOtp,
  });

  /// Creates an instance configured with an activation code.
  factory PowerAuthActivation.fromActivationCode({
    required String activationCode,
    required String name,
    String? extras,
    Map<String, dynamic>? customAttributes,
    String? additionalActivationOtp,
  }) {
    return PowerAuthActivation._(
      activationName: name,
      activationCode: activationCode,
      extras: extras,
      customAttributes: customAttributes,
      additionalActivationOtp: additionalActivationOtp,
    );
  }

  /// Creates an instance configured with a recovery activation code and PUK.
  factory PowerAuthActivation.fromRecoveryCode({
    required String recoveryCode,
    required String recoveryPuk,
    required String name,
    String? extras,
    Map<String, dynamic>? customAttributes,
  }) {
    return PowerAuthActivation._(
      activationName: name,
      recoveryCode: recoveryCode,
      recoveryPuk: recoveryPuk,
      extras: extras,
      customAttributes: customAttributes,
    );
  }

  /// Creates an instance configured with identity attributes for custom activation purposes.
  factory PowerAuthActivation.fromIdentityAttributes({
    required Map<String, dynamic> identityAttributes,
    required String name,
    String? extras,
    Map<String, dynamic>? customAttributes,
  }) {
    return PowerAuthActivation._(
      activationName: name,
      identityAttributes: identityAttributes,
      extras: extras,
      customAttributes: customAttributes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'activationName': activationName,
      'activationCode': activationCode,
      'recoveryCode': recoveryCode,
      'recoveryPuk': recoveryPuk,
      'identityAttributes': identityAttributes,
      'extras': extras,
      'customAttributes': customAttributes,
      'additionalActivationOtp': additionalActivationOtp,
    }..removeWhere((key, value) => value == null);
  }
}
