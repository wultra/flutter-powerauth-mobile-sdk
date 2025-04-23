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

import 'powerauth_recovery_activation_data.dart';

/// Success object returned by the `createActivation` call.
class PowerAuthCreateActivationResult {

  /// Decimalized fingerprint calculated from device's and server's public keys.
  final String activationFingerprint;

  /// If supported and enabled on the server, then the object contains "Recovery Code" and PUK,
  /// created for this particular activation. Your application should display these values to the user
  /// and forget them immediately. You should NEVER store these values persistently on the device.
  final PowerAuthRecoveryActivationData? activationRecovery;

  /// When available, the contents of this object depend on your enrollment server configuration.
  final Map<String, dynamic>? customAttributes;

  PowerAuthCreateActivationResult({
    required this.activationFingerprint,
    this.activationRecovery,
    this.customAttributes,
  });

  factory PowerAuthCreateActivationResult.fromMap(Map<dynamic, dynamic> map) {
    return PowerAuthCreateActivationResult(
      activationFingerprint: map['activationFingerprint'] as String,
      activationRecovery:
          map['activationRecovery'] != null
              ? PowerAuthRecoveryActivationData.fromMap(
                map['activationRecovery'] as Map,
              )
              : null,
      customAttributes:
          map['customAttributes'] != null
              ? Map<String, dynamic>.from(map['customAttributes'] as Map)
              : null,
    );
  }
}
