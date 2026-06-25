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


import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';

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
}
