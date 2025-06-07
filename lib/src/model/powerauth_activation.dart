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

import 'package:flutter_powerauth_mobile_sdk_plugin/src/model/powerauth_oidc_parameters.dart';

/// Contains activation data required for the activation creation.
/// Use one of the factory constructors to create an instance based on the activation type.
class PowerAuthActivation {

  /// Activation name to be assigned to new activation. Recommended to set to device name.
  final String activationName;

  /// Activation code, obtained either via QR code scanning or by manual entry.
  /// May contain an optional signature part if scanned from a QR code.
  final String? activationCode;

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

  /// OpenID Connect parameters for activation.
  final PowerAuthOIDCParameters? oidcParameters;

  // Private constructor to enforce factory usage
  PowerAuthActivation._({
    required this.activationName,
    this.activationCode,
    this.identityAttributes,
    this.oidcParameters,
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

  /// Creates an instance configured with OpenID Connect parameters for activation.
  factory PowerAuthActivation.fromOIDC({
    required PowerAuthOIDCParameters oidcParameters,
    required String name,
    String? extras,
    Map<String, dynamic>? customAttributes,
  }) {
    return PowerAuthActivation._(
      activationName: name,
      oidcParameters: oidcParameters,
      extras: extras,
      customAttributes: customAttributes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'activationName': activationName,
      'activationCode': activationCode,
      'identityAttributes': identityAttributes,
      'extras': extras,
      'customAttributes': customAttributes,
      'additionalActivationOtp': additionalActivationOtp,
      'oidcParameters': oidcParameters?.toMap(),
    }..removeWhere((key, value) => value == null);
  }
}
