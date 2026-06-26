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


import 'powerauth_biometry_configuration.dart';
import 'powerauth_client_configuration.dart';
import 'powerauth_configuration.dart';
import 'powerauth_keychain_configuration.dart';
import 'powerauth_sharing_configuration.dart';

class PowerAuthInstanceConfigurationHolder {
  final PowerAuthConfiguration configuration;
  final PowerAuthClientConfiguration? clientConfiguration;
  final PowerAuthBiometryConfiguration? biometryConfiguration;
  final PowerAuthKeychainConfiguration? keychainConfiguration;
  final PowerAuthSharingConfiguration? sharingConfiguration;

  PowerAuthInstanceConfigurationHolder({
    required this.configuration,
    this.biometryConfiguration,
    this.keychainConfiguration,
    this.clientConfiguration,
    this.sharingConfiguration
  });

  factory PowerAuthInstanceConfigurationHolder.fromMap(Map<dynamic, dynamic> map) {
    T? parse<T>(String key, T Function(Map<String, dynamic>) fromMap) {
      final value = map[key];
      return value != null ? fromMap((value as Map).cast<String, dynamic>()) : null;
    }

    return PowerAuthInstanceConfigurationHolder(
      configuration: parse('configuration', PowerAuthConfiguration.fromMap)!,
      clientConfiguration: parse('clientConfiguration', PowerAuthClientConfiguration.fromMap),
      biometryConfiguration: parse('biometryConfiguration', PowerAuthBiometryConfiguration.fromMap),
      keychainConfiguration: parse('keychainConfiguration', PowerAuthKeychainConfiguration.fromMap),
      sharingConfiguration: parse('sharingConfiguration', PowerAuthSharingConfiguration.fromMap),
    );
  }
}
