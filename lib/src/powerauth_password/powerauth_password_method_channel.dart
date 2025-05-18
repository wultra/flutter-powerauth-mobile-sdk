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

import 'powerauth_password_platform_interface.dart';
import '../utils/method_channel_helper.dart';

/// Method channel implementation for PowerAuth password operations.
class PowerAuthPasswordMethodChannel extends PowerAuthPasswordPlatform
    with MethodChannelHelper {
  @override
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel('powerauth_plugin');

  @override
  Future<String> initialize({
    required bool destroyOnUse,
    String? powerAuthInstanceId,
    int? autoReleaseTimeMillis,
  }) async {
    final Map<String, dynamic> args = {'destroyOnUse': destroyOnUse};
    if (powerAuthInstanceId != null) {
      args['ownerId'] = powerAuthInstanceId;
    }

    if (autoReleaseTimeMillis != null) {
      args['autoreleaseTime'] = autoReleaseTimeMillis;
    }

    return await invokeMethod<String>('password_initialize', args);
  }

  @override
  Future<void> release(String objectId) async {
    await invokeNullableMethod<void>('password_release', {
      'objectId': objectId,
    });
  }

  @override
  Future<int> length(String objectId) async {
    final result = await invokeMethod<int>('password_length', {
      'objectId': objectId,
    });
    return result;
  }

  @override
  Future<void> clear(String objectId) async {
    await invokeMethod<void>('password_clear', {'objectId': objectId});
  }

  @override
  Future<int> addCharacter(String objectId, int character) async {
    return await invokeMethod<int>('password_addCharacter', {
      'objectId': objectId,
      'character': character,
    });
  }

  @override
  Future<int> insertCharacter(String objectId, int character, int at) async {
    return await invokeMethod<int>('password_insertCharacter', {
      'objectId': objectId,
      'character': character,
      'position': at,
    });
  }

  @override
  Future<int> removeCharacterAt(String objectId, int position) async {
    return await invokeMethod<int>('password_removeCharacterAt', {
      'objectId': objectId,
      'position': position,
    });
  }

  @override
  Future<int> removeLastCharacter(String objectId) async {
    return await invokeMethod<int>('password_removeLastCharacter', {
      'objectId': objectId,
    });
  }

  @override
  Future<bool> isEqualTo(String objectId, String otherObjectId) async {
    return await invokeMethod<bool>('password_isEqualTo', {
      'objectId': objectId,
      'otherObjectId': otherObjectId,
    });
  }
}
