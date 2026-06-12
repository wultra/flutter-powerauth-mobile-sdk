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

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'powerauth_activation_code_utils_platform_interface.dart';
import '../utils/method_channel_helper.dart';
import '../model/powerauth_activation_code.dart';
import '../model/powerauth_error.dart';
import '../powerauth_password/powerauth_password.dart';
import '../powerauth_utils/powerauth_utils.dart';

/// Method channel implementation for PowerAuth utility functions.
class PowerAuthUtilsMethodChannel extends PowerAuthUtilsPlatform
    with MethodChannelHelper {

  @override
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel(
    'powerauth_plugin',
  );

  static Future<dynamic> _serializePassword(Object password) async {
    if (password is PowerAuthPassword) {
      return await password.toRawPasswordMap();
    } else if (password is String) {
      return password;
    } else {
      throw ArgumentError(
        'Password must be a String or a PowerAuthPassword object.',
      );
    }
  }

  @override
  Future<PowerAuthActivationCode> parseActivationCode(
    String activationCode,
  ) async {
    final result = await invokeMethod<Map<dynamic, dynamic>>(
      'util_parseActivationCode',
      {'activationCode': activationCode},
    );
    return PowerAuthActivationCode.fromMap(result);
  }

  @override
  Future<bool> validateActivationCode(String activationCode) async {
    return await invokeMethod<bool>('util_validateActivationCode', {
      'activationCode': activationCode,
    });
  }

  @override
  Future<bool> validateTypedCharacter(int character) async {
    return await invokeMethod<bool>('util_validateTypedCharacter', {
      'character': character,
    });
  }

  @override
  Future<int> correctTypedCharacter(int character) async {
    return await invokeMethod<int>('util_correctTypedCharacter', {
      'character': character,
    });
  }

  @override
  Future<PowerAuthEnvironmentInfo> getEnvironmentInfo() async {
    final result = await invokeMethod<Map<dynamic, dynamic>>('util_getEnvironmentInfo', null);
    return PowerAuthEnvironmentInfo.fromJson(result);
  }

  @override
  Future<void> migrateiOSSharingConfiguration(String? fromAppGroup, String? toAppGroup) async {
    // The keychain initialization flag is an iOS-only concept stored in UserDefaults.
    // On any other platform this is a no-op, so we avoid invoking the native channel.
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    await invokeMethod<void>('util_migrateSharingConfiguration', {
      'fromAppGroup': fromAppGroup,
      'toAppGroup': toAppGroup,
    });
  }

  @override
  Future<PinTestResult> testPin(Object pin) async {

    // Validate pin type before serialization
    if (pin is! String && pin is! PowerAuthPassword) {
      throw ArgumentError(
        'PIN must be a String or a PowerAuthPassword object.',
      );
    }

    final result = await invokeMethod<Map<dynamic, dynamic>>('util_testPin', {
      'pin': await _serializePassword(pin),
    });

    return PinTestResult.fromMap(result);
  }
}
