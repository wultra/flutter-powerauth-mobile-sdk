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

/// Contains complex information about the type and state of biometry on the device.
class PowerAuthBiometryInfo {

  /// Whether biometric authentication is supported on the system.
  /// Note: On iOS, this is `false` if biometry is not enrolled or locked down.
  /// Use [biometryType] and [canAuthenticate] for more details.
  final bool isAvailable;

  /// The type of biometry supported on the system.
  final PowerAuthBiometryType biometryType;

  /// Check whether biometric authentication is available and biometric data are enrolled.
  final PowerAuthBiometryStatus canAuthenticate;

  PowerAuthBiometryInfo({
    required this.isAvailable,
    required this.biometryType,
    required this.canAuthenticate,
  });

  factory PowerAuthBiometryInfo.fromMap(Map<dynamic, dynamic> map) {
    PowerAuthBiometryType parseType(String? typeString) {
      if (typeString == null) { 
        return PowerAuthBiometryType.none;
      }

      try {
        return PowerAuthBiometryType.values.firstWhere(
          (e) => e.name == typeString,
        );
      } catch (e) {
        PowerAuthLogger.warning(
          () => "Unknown PowerAuthBiometryType received: $typeString",
        );

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
        PowerAuthLogger.warning(
          () => "Unknown PowerAuthBiometryStatus received: $statusString",
        );

        return PowerAuthBiometryStatus.notSupported;
      }
    }

    return PowerAuthBiometryInfo(
      isAvailable: map['isAvailable'] as bool,
      biometryType: parseType(map['biometryType'] as String?),
      canAuthenticate: parseStatus(map['canAuthenticate'] as String?),
    );
  }
}
