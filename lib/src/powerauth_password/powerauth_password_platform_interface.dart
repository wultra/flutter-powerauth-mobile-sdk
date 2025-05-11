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

import 'powerauth_password_method_channel.dart';

/// Platform interface for PowerAuth password operations.
abstract class PowerAuthPasswordPlatform extends PlatformInterface {
  PowerAuthPasswordPlatform() : super(token: _token);

  static final Object _token = Object();

  static PowerAuthPasswordPlatform _instance = PowerAuthPasswordMethodChannel();

  static PowerAuthPasswordPlatform get instance => _instance;

  static set instance(PowerAuthPasswordPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String> initialize({
    required bool destroyOnUse,
    String? powerAuthInstanceId,
    int? autoReleaseTimeMillis,
  }) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  Future<void> release(String objectId) {
    throw UnimplementedError('release() has not been implemented.');
  }

  Future<int> length(String objectId) {
    throw UnimplementedError('length() has not been implemented.');
  }

  Future<void> clear(String objectId) {
    throw UnimplementedError('clear() has not been implemented.');
  }

  Future<int> addCharacter(String objectId, int character) {
    throw UnimplementedError('addCharacter() has not been implemented.');
  }

  Future<int> insertCharacter(String objectId, int character, int at) {
    throw UnimplementedError('insertCharacter() has not been implemented.');
  }

  Future<int> removeCharacterAt(String objectId, int position) {
    throw UnimplementedError('removeCharacterAt() has not been implemented.');
  }

  Future<int> removeLastCharacter(String objectId) {
    throw UnimplementedError('removeLastCharacter() has not been implemented.');
  }

  Future<bool> isEqualTo(String objectId, String otherObjectId) {
    throw UnimplementedError('isEqualTo() has not been implemented.');
  }
}
