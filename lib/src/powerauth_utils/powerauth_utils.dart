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

import '../powerauth_activation_code_utils/powerauth_activation_code_utils_platform_interface.dart';

/// The `PowerAuthUtils` class provides utility methods for the PowerAuth SDK.
class PowerAuthUtils {

  PowerAuthUtils._();

  static PowerAuthUtilsPlatform get _platform => PowerAuthUtilsPlatform.instance;

  /// Returns information about the current environment, such as system name, version, device ID,
  /// and the PowerAuth SDK version.
  static Future<PowerAuthEnvironmentInfo> getEnvironmentInfo() => _platform.getEnvironmentInfo();
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
        sdkVersion: libraryVersion, // Use the library version defined in version.dart
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
