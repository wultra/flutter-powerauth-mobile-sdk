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

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../model/powerauth_activation_code.dart';
import '../model/powerauth_error.dart';
import '../powerauth_utils/powerauth_utils.dart';

import 'powerauth_activation_code_utils_method_channel.dart';

/// Platform interface for PowerAuth utility functions.
abstract class PowerAuthUtilsPlatform extends PlatformInterface {
  PowerAuthUtilsPlatform() : super(token: _token);

  static final Object _token = Object();

  static PowerAuthUtilsPlatform _instance = PowerAuthUtilsMethodChannel();

  static PowerAuthUtilsPlatform get instance => _instance;

  static set instance(PowerAuthUtilsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<PowerAuthActivationCode> parseActivationCode(String activationCode) {
    throw UnimplementedError('parseActivationCode() has not been implemented.');
  }

  Future<bool> validateActivationCode(String activationCode) {
    throw UnimplementedError(
      'validateActivationCode() has not been implemented.',
    );
  }

  Future<bool> validateTypedCharacter(int character) {
    throw UnimplementedError(
      'validateTypedCharacter() has not been implemented.',
    );
  }

  Future<int> correctTypedCharacter(int character) {
    throw UnimplementedError(
      'correctTypedCharacter() has not been implemented.',
    );
  }

  Future<PowerAuthEnvironmentInfo> getEnvironmentInfo() {
    throw UnimplementedError('getEnvironmentInfo() has not been implemented.');
  }

  /// Migrates the iOS keychain initialization flag between two `UserDefaults` suites identified by
  /// their app group names. No-op on platforms other than iOS.
  ///
  /// See [PowerAuthUtils.migrateiOSSharingConfiguration] for details.
  Future<void> migrateiOSSharingConfiguration(String? fromAppGroup, String? toAppGroup) {
    throw UnimplementedError('migrateiOSSharingConfiguration() has not been implemented.');
  }

  // TODO: do we want to move this to a dedicated PassphraseMeter module?
  Future<PinTestResult> testPin(Object pin) {
    throw UnimplementedError('testPin() has not been implemented.');
  }
}
