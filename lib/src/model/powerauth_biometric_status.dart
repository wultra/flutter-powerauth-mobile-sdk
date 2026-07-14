/*
 * Copyright 2026 Wultra s.r.o.
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

import '../logging/powerauth_logger.dart';

/// Defines biometry types supported on the system.
/// In case a device supports multiple biometry types, then [generic] is returned.
enum PowerAuthBiometryType {

  /// There's no biometry support on the device.
  none,

  /// It's not possible to determine the exact type of biometry (e.g., Android 10+ with multiple types).
  generic,

  /// Fingerprint scanner/TouchID is present on the device.
  fingerprint,

  /// Face scanner/FaceID is present on the device.
  face,

  /// Iris scanner is present on the device.
  iris,
}

/// Defines various states of biometric authentication support on the system.
/// The status may change during the application lifetime, unless it's [notSupported].
enum PowerAuthBiometryStatus {

  /// The biometric authentication can be used right now.
  ok,

  /// The biometric authentication is not supported on the device (missing hardware/OS support).
  notSupported,

  /// Biometric authentication is supported, but no biometric data is enrolled.
  notEnrolled,

  /// The biometric authentication is not available at this time. Retry later.
  notAvailable,

  /// Biometric authentication is locked out due to too many failed attempts (iOS only).
  lockout,
}

/// Contains information about the availability of biometric authentication
/// for a PowerAuth instance.
class PowerAuthBiometricStatus {

  /// Whether biometric authentication is fully available for the current activation.
  final bool isAuthenticationWithBiometricsAvailable;

  /// Whether a biometric factor is configured for the current activation.
  final bool isBiometricFactorConfigured;

  /// The current biometric authentication status reported by the system.
  final PowerAuthBiometryStatus systemStatus;

  /// The type of biometric authentication available on the device.
  final PowerAuthBiometryType biometryType;

  PowerAuthBiometricStatus({
    required this.isAuthenticationWithBiometricsAvailable,
    required this.isBiometricFactorConfigured,
    required this.systemStatus,
    required this.biometryType,
  });

  factory PowerAuthBiometricStatus.fromMap(Map<dynamic, dynamic> map) {
    PowerAuthBiometryType parseType(String? typeString) {
      if (typeString == null) {
        return PowerAuthBiometryType.none;
      }

      try {
        return PowerAuthBiometryType.values.firstWhere(
          (e) => e.name == typeString,
        );
      } catch (e) {
        PowerAuthLogger.warning("Unknown PowerAuthBiometryType received: $typeString");

        return PowerAuthBiometryType.none;
      }
    }

    PowerAuthBiometryStatus parseStatus(String? statusString) {
      if (statusString == null) {
        return PowerAuthBiometryStatus.notSupported;
      }

      try {
        return PowerAuthBiometryStatus.values.firstWhere(
          (e) => e.name == statusString,
        );
      } catch (e) {
        PowerAuthLogger.warning("Unknown PowerAuthBiometryStatus received: $statusString");

        return PowerAuthBiometryStatus.notSupported;
      }
    }

    return PowerAuthBiometricStatus(
      isAuthenticationWithBiometricsAvailable: map['isAuthenticationWithBiometricsAvailable'] as bool,
      isBiometricFactorConfigured: map['isBiometricFactorConfigured'] as bool,
      systemStatus: parseStatus(map['systemStatus'] as String?),
      biometryType: parseType(map['biometryType'] as String?),
    );
  }
}
