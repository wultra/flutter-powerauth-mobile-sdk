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

import 'package:flutter_powerauth_mobile_sdk_plugin/src/version.dart';

import '../model/powerauth_sharing_configuration.dart';
import '../powerauth_activation_code_utils/powerauth_activation_code_utils_platform_interface.dart';

/// The `PowerAuthUtils` class provides utility methods for the PowerAuth SDK.
class PowerAuthUtils {

  PowerAuthUtils._();

  static PowerAuthUtilsPlatform get _platform => PowerAuthUtilsPlatform.instance;

  /// Returns information about the current environment, such as system name, version, device ID,
  /// and the PowerAuth SDK version.
  static Future<PowerAuthEnvironmentInfo> getEnvironmentInfo() => _platform.getEnvironmentInfo();

  /// Migrates the iOS keychain initialization state between two activation data sharing setups.
  ///
  /// PowerAuth SDK for iOS keeps track of whether the application has been reinstalled. When you
  /// start sharing activation data between an application and its app extension (or change the
  /// sharing setup), this state has to be moved to the new setup. Otherwise the SDK may evaluate
  /// the activation incorrectly after the configuration change.
  ///
  /// Call this method at the application's startup, **before** any [PowerAuth] instance is
  /// configured and used.
  ///
  /// > Use this method only after consulting Wultra support or engineers. Incorrect usage can lead
  /// > to scenarios where users lose access to their activation data.
  ///
  /// This operation is a **no-op on Android** (it is an iOS-only concept).
  ///
  /// See the native documentation for the rationale and original implementation:
  /// https://developers.wultra.com/components/powerauth-mobile-sdk/1.9.x/documentation/PowerAuth-SDK-for-iOS-Extensions#userdefaults-migration
  ///
  /// - [from]: the source configuration to migrate from.
  /// - [to]: the destination configuration to migrate to.
  ///
  /// Throws [ArgumentError] when both [from] and [to] are `null`, or when both are provided but
  /// share the same [PowerAuthSharingConfiguration.appGroup] (there would be nothing to migrate).
  static Future<void> migrateiOSSharingConfiguration({
    PowerAuthSharingConfiguration? from,
    PowerAuthSharingConfiguration? to,
  }) {
    // At least one side must be provided, otherwise there is nothing to migrate between.
    if (from == null && to == null) {
      throw ArgumentError('At least one of "from" or "to" must be provided.');
    }

    // Migrating within the same setup is a no-op and most likely indicates a mistake.
    if (from != null && to != null && from.appGroup == to.appGroup) {
      throw ArgumentError.value(
        to.appGroup,
        'to.appGroup',
        '"from" and "to" must not share the same appGroup',
      );
    }

    return _platform.migrateiOSSharingConfiguration(from?.appGroup, to?.appGroup);
  }
}

/// Class representing the environment information for the PowerAuth SDK.
/// This includes system details, application version or device information.
class PowerAuthEnvironmentInfo {

    /// System name, for example "iOS", "Android", "iPadOS", ...
    String systemName;
    /// Version of the system
    String systemVersion;

    /// Application version, e.g. "1.0.0".
    String? applicationVersion;
    /// Host application identifier, for example "com.wultra.demoapp"
    String? applicationIdentifier;

    /// For example "apple" or "Samsung"
    String deviceManufacturer;
    /// Device ID, for example "iPhone9,2"
    String deviceId;

    /// PowerAuth Flutter SDK version, for example "4.0.0"
    String sdkVersion;

    PowerAuthEnvironmentInfo({
      required this.systemName,
      required this.systemVersion,
      this.applicationVersion,
      this.applicationIdentifier,
      required this.deviceManufacturer,
      required this.deviceId,
      required this.sdkVersion,
    });

    factory PowerAuthEnvironmentInfo.fromJson(Map<dynamic, dynamic> json) {
      return PowerAuthEnvironmentInfo(
        systemName: json['systemName'] as String,
        systemVersion: json['systemVersion'] as String,
        applicationVersion: json['applicationVersion'] as String?,
        applicationIdentifier: json['applicationIdentifier'] as String?,
        deviceManufacturer: json['deviceManufacturer'] as String,
        deviceId: json['deviceId'] as String,
        sdkVersion: powerAuthFlutterVersion, // Use the library version defined in version.dart
      );
    }

    Map<String, dynamic> toJson() {
      return {
        'systemName': systemName,
        'systemVersion': systemVersion,
        'applicationVersion': applicationVersion,
        'applicationIdentifier': applicationIdentifier,
        'deviceManufacturer': deviceManufacturer,
        'deviceId': deviceId,
        'sdkVersion': sdkVersion,
      };
    }
}
