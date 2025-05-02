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

// import '../model/powerauth_error.dart';
// import 'powerauth_password_platform_interface.dart';
import '../model/base_native_object.dart';

/// Represents a secure storage for a user's password or PIN.
/// Extends [BaseNativeObject] to handle native object lifecycle.
class PowerAuthPassword extends BaseNativeObject {

  // Configuration specific to password
  final bool _destroyOnUse;

  // Platform instance accessor - static for easy access in overrides
  // static PowerAuthPasswordPlatform get _platform =>
  //     PowerAuthPasswordPlatform.instance;

  // TODO: Temporary backing field until NativeObject is implemented
  String field = "";
  /// Creates a container for a secure password.
  ///
  /// The underlying native resources are allocated lazily when the password is first
  /// used in an operation (e.g., added characters, used for authentication).
  ///
  /// - `destroyOnUse`: If `true`, the native password object is marked to be destroyed
  ///                   after its first use in a cryptographic operation (e.g., signing,
  ///                   vault unlock, password change). Defaults to `true`.
  PowerAuthPassword({bool destroyOnUse = true}) : _destroyOnUse = destroyOnUse;

  factory PowerAuthPassword.fromString(String password, {bool destroyOnUse = true}) {
    final pass = PowerAuthPassword(destroyOnUse: destroyOnUse);
    pass.field = password;
    return pass;
  }

  @override
  Future<String> createNativeObject() async {
    //return _platform.initialize(destroyOnUse: _destroyOnUse);
    return "";
  }

  @override
  Future<void> releaseNativeObject(String objectId) async {
    //return _platform.release(objectId);
  }

  /// Returns the number of characters stored in the password.
  // Future<int> length() => withObjectId((id) => _platform.length(id));
  Future<int> length() async {
    return field.length;
  }

  /// Clears the content of the password.
  // Future<void> clear() => withObjectId((id) => _platform.clear(id));
  Future<void> clear() async {
    field = "";
  }

  /// Determines whether the stored password is empty.
  Future<bool> isEmpty() async {
    // TODO: confirm this is always enough of a truth check
    // if (currentObjectId == null) {
    //   return true;
    // }

    // return await length() == 0;
    return field.isEmpty;
  }

  /// Appends a character to the end of the password.
  /// If more than one character is provided, only the first one is used.
  Future<int> addCharacter(String character) async {
    if (character.isNotEmpty) {
      final char = character[0];
      field += char;
    }
    return field.length;
    // Future<int> addCharacter(Object character) => withObjectId(
    //   (id) => _platform.addCharacter(id, _getCodePoint(character)),
    // );
  }

  /// Appends a character to the end of the password.
  /// If more than one character is provided, only the first one is used.
  Future<int> addCodePoint(int characterCodePoint) async {
    final char = String.fromCharCode(characterCodePoint);
    field += char;
    return field.length;
    // Future<int> addCharacter(Object character) => withObjectId(
    //   (id) => _platform.addCharacter(id, _getCodePoint(character)),
    // );
  }

  /// Inserts a character at the specified position.
  // Future<int> insertCharacter(Object character, int at) => withObjectId(
  //   (id) => _platform.insertCharacter(id, _getCodePoint(character), at),
  // );

  // Future<int> insertCharacter(Object character, int at) async {
  //   // not implemented
  //   return field.length;
  // }

  /// Removes the character at the specified position.
  // Future<int> removeCharacterAt(int position) =>
  //     withObjectId((id) => _platform.removeCharacterAt(id, position));
  // Future<int> removeCharacterAt(int position) async {
  //   // not implemented
  //   return field.length;
  // }

  /// Removes the last character.
  // Future<int> removeLastCharacter() =>
  //     withObjectId((id) => _platform.removeLastCharacter(id));
  Future<int> removeLastCharacter() async {
    if (field.isNotEmpty) {
      field = field.substring(0, field.length - 1);
    }
    return field.length;
  }

  /// Compares this password with another [PowerAuthPassword].
  Future<bool> isEqualTo(PowerAuthPassword other) async {
    // final id1 = await ensureNativeObjectInitialized();
    // final id2 = await other.ensureNativeObjectInitialized();

    // return _platform.isEqualTo(id1, id2);
    return field == other.field;
  }

  // int _getCodePoint(Object character) {
  //   if (character is int) {
  //     return character;
  //   } else if (character is String) {
  //     if (character.isEmpty) {
  //       throw PowerAuthException(
  //         code: PowerAuthErrorCode.wrongParameter,
  //         message: 'String must not be empty',
  //       );
  //     }

  //     return character.runes.first;
  //   } else {
  //     throw PowerAuthException(
  //       code: PowerAuthErrorCode.wrongParameter,
  //       message: 'Must be a String or int (Unicode code point)',
  //     );
  //   }
  // }

  /// Internal method for serialization.
  /// Ensures the native object is initialized.
  Future<Map<String, dynamic>> toRawPasswordMap() async {
    return await withObjectId(
      (id) async => {'password': field, 'destroyOnUse': _destroyOnUse},
    );
  }
}
