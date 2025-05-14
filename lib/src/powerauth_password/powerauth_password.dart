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

import 'package:meta/meta.dart';

import '../model/powerauth_error.dart';
import 'powerauth_password_platform_interface.dart';
import '../model/base_native_object.dart';

/// Represents a secure storage for a user's password or PIN.
/// Extends [BaseNativeObject] to handle native object lifecycle.
class PowerAuthPassword extends BaseNativeObject {

  // Configuration specific to password
  final bool _destroyOnUse;
  final String? _powerAuthInstanceId;
  final int? _autoReleaseTimeMillis;

  // Platform instance accessor - static for easy access in overrides
  static PowerAuthPasswordPlatform get _platform =>
      PowerAuthPasswordPlatform.instance;

  /// Creates a container for a secure password.
  ///
  /// The underlying native resources are allocated lazily when the password is first
  /// used in an operation (e.g., added characters, used for authentication).
  ///
  /// - `destroyOnUse`: If `true`, the native password object is marked to be destroyed
  ///                   after its first use in a cryptographic operation (e.g., signing,
  ///                   vault unlock, password change). Defaults to `true`.
  /// - `powerAuthInstanceId`: Optional. If provided, associates this password object with a
  ///                      specific `PowerAuth` instance ID for lifecycle management or debugging.
  /// - `autoReleaseTimeMillis`: Optional. Specifies a custom auto-release time in milliseconds
  ///                            for the native object. Platform defaults apply if not set.
  PowerAuthPassword({
    bool destroyOnUse = true,
    String? powerAuthInstanceId,
    int? autoReleaseTimeMillis,
  }) : _destroyOnUse = destroyOnUse,
       _powerAuthInstanceId = powerAuthInstanceId,
       _autoReleaseTimeMillis = autoReleaseTimeMillis;

  static Future<PowerAuthPassword> fromString(
    String password, {
    bool destroyOnUse = true,
    String? powerAuthInstanceId,
    int? autoReleaseTimeMillis,
  }) async {
    final pass = PowerAuthPassword(
      destroyOnUse: destroyOnUse,
      powerAuthInstanceId: powerAuthInstanceId,
      autoReleaseTimeMillis: autoReleaseTimeMillis,
    );
    for (final character in password.runes) {
      await pass.addCodePoint(character);
    }
    return pass;
  }

  @override
  @protected
  Future<String> createNativeObject() async {
    return _platform.initialize(
      destroyOnUse: _destroyOnUse,
      powerAuthInstanceId: _powerAuthInstanceId,
      autoReleaseTimeMillis: _autoReleaseTimeMillis,
    );
  }

  @override
  @protected
  Future<void> releaseNativeObject(String objectId) async {
    return _platform.release(objectId);
  }

  /// Returns the number of characters stored in the password.
  Future<int> length() => withObjectId((id) => _platform.length(id));

  /// Clears the content of the password.
  Future<void> clear() => withObjectId((id) => _platform.clear(id));

  /// Determines whether the stored password is empty.
  Future<bool> isEmpty() async {
    return await length() == 0;
  }

  /// Appends a character to the end of the password.
  /// If more than one character is provided, only the first one is used.
  Future<int> addCharacter(String character) async {
    return addCodePoint(_getCodePoint(character));
  }

  /// Appends a character to the end of the password.
  /// If more than one character is provided, only the first one is used.
  Future<int> addCodePoint(int codePoint) => withObjectId((id) => _platform.addCharacter(id, codePoint));

  /// Inserts a character at the specified position.
  Future<int> insertCharacter(String character, int at) async {
    return insertCodePoint(_getCodePoint(character), at);
  }

  Future<int> insertCodePoint(int codePoint, int at) => withObjectId((id) => _platform.insertCharacter(id, codePoint, at));

  /// Removes the character at the specified position.
  Future<int> removeCharacterAt(int position) =>
      withObjectId((id) => _platform.removeCharacterAt(id, position));

  /// Removes the last character.
  Future<int> removeLastCharacter() =>
      withObjectId((id) => _platform.removeLastCharacter(id));

  /// Compares this password with another [PowerAuthPassword].
  Future<bool> isEqualTo(PowerAuthPassword other) async {
    final id1 = await ensureNativeObjectInitialized();
    final id2 = await other.ensureNativeObjectInitialized();

    return _platform.isEqualTo(id1, id2);
  }

  int _getCodePoint(String character) {
    if (character.isEmpty) {
      throw PowerAuthException(
        code: PowerAuthErrorCode.wrongParameter,
        message: 'String must not be empty',
      );
    }

    return character.runes.first;
  }

  /// Internal method for serialization.
  /// Ensures the native object is initialized.
  Future<Map<String, dynamic>> toRawPasswordMap() async {
    return await withObjectId((id) async {
      return {
        'objectId': id,
        'destroyOnUse': _destroyOnUse,
        'ownerId': _powerAuthInstanceId,
        'autoreleaseTime': _autoReleaseTimeMillis
      }..removeWhere((key, value) => value == null);
    });
  }
}
