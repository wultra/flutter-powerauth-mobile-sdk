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

import '../model/native_object_handle.dart';
import '../model/powerauth_error.dart';
import 'powerauth_password_platform_interface.dart';

/// Represents a secure storage for a user's password or PIN.
class PowerAuthPassword {

  // Configuration specific to password
  final bool destroyOnUse;
  final String? powerAuthInstanceId;
  final int? autoReleaseTimeMillis;
  late final NativeObjectHandle _handle;

  // Tail of the queue that serializes operations, so that an operation with
  // several native calls is not interleaved with another operation.
  Future<void> _tail = Future.value();
  int _pendingCount = 0;

  // Platform instance accessor - static for easy access in overrides
  static PowerAuthPasswordPlatform get _platform => PowerAuthPasswordPlatform.instance;

  /// Creates a container for a secure password.
  ///
  /// The underlying native resources are allocated lazily when the password is first
  /// used in an operation (e.g., added characters, used for authentication).
  ///
  /// - [destroyOnUse]: If `true`, the native password object is marked to be destroyed
  ///                   after its first use in a cryptographic operation (e.g., signing,
  ///                   vault unlock, password change). Defaults to `true`.
  /// - [powerAuthInstanceId]: Optional. If provided, associates this password object with a
  ///                      specific `PowerAuth` instance ID for lifecycle management or debugging.
  /// - [autoReleaseTimeMillis]: Optional. Specifies a custom auto-release time in milliseconds
  ///                            for the native object. Platform defaults apply if not set.
  PowerAuthPassword({
    this.destroyOnUse = true,
    this.powerAuthInstanceId,
    this.autoReleaseTimeMillis,
  }) {
    _handle = NativeObjectHandle.lazy(
      () => _platform.initialize(
        destroyOnUse: destroyOnUse,
        powerAuthInstanceId: powerAuthInstanceId,
        autoReleaseTimeMillis: autoReleaseTimeMillis,
      ),
    );
  }

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
    // TODO: consider using a more efficient way
    for (final character in password.runes) {
      await pass.addCodePoint(character);
    }
    return pass;
  }

  /// Returns the number of Unicode code points stored in the password.
  Future<int> length() => _enqueue(() => _handle.withObjectId((id) => _platform.length(id)));

  /// Clears the content of the password.
  Future<void> clear() => _enqueue(() => _handle.withObjectId((id) => _platform.clear(id)));

  /// Releases the underlying native password object.
  Future<void> release() => _enqueue(() => _handle.release());

  /// Determines whether the stored password is empty.
  Future<bool> isEmpty() async {
    return await length() == 0;
  }

  /// Appends every Unicode code point of [character] to the end of the password
  /// and returns the number of code points stored in the password.
  ///
  /// A visible character can consist of more than one code point. For example,
  /// `'👍🏽'` adds two code points, so the length grows by 2.
  ///
  /// If [character] is empty, `PowerAuthErrorCode.wrongParameter` is reported.
  @Deprecated('Use addCodePoint() instead. This method will be removed in a future major version.')
  Future<int> addCharacter(String character) => _enqueue(() async {
    var length = 0;
    for (final codePoint in _getCodePoints(character)) {
      length = await _addCodePoint(codePoint);
    }
    return length;
  });

  /// Appends a Unicode code point to the end of the password and returns
  /// the number of code points stored in the password.
  ///
  /// The code point must be in range 0 up to 0x10FFFF, otherwise
  /// `PowerAuthErrorCode.wrongParameter` is reported.
  Future<int> addCodePoint(int codePoint) => _enqueue(() => _addCodePoint(codePoint));

  /// Inserts every Unicode code point of [character] at the specified position
  /// and returns the number of code points stored in the password.
  ///
  /// A visible character can consist of more than one code point. For example,
  /// `'👍🏽'` inserts two code points, so the length grows by 2.
  /// The position [at] is counted in code points and must be in range 0 up to length,
  /// otherwise `PowerAuthErrorCode.wrongParameter` is reported.
  ///
  /// If [character] is empty, `PowerAuthErrorCode.wrongParameter` is reported.
  @Deprecated('Use insertCodePoint() instead. This method will be removed in a future major version.')
  Future<int> insertCharacter(String character, int at) => _enqueue(() async {
    var length = 0;
    var position = at;
    for (final codePoint in _getCodePoints(character)) {
      length = await _insertCodePoint(codePoint, position++);
    }
    return length;
  });

  /// Inserts a Unicode code point at the specified position and returns
  /// the number of code points stored in the password.
  ///
  /// The code point must be in range 0 up to 0x10FFFF and the position [at] must be
  /// in range 0 up to length, otherwise `PowerAuthErrorCode.wrongParameter` is reported.
  Future<int> insertCodePoint(int codePoint, int at) => _enqueue(() => _insertCodePoint(codePoint, at));

  /// Removes the code point at the specified position and returns
  /// the remaining number of code points stored in the password.
  ///
  /// This method works the same as [removeCodePointAt].
  @Deprecated('Use removeCodePointAt() instead. This method will be removed in a future major version.')
  Future<int> removeCharacterAt(int position) => removeCodePointAt(position);

  /// Removes the code point at the specified position and returns
  /// the remaining number of code points stored in the password.
  ///
  /// A visible character can consist of more than one code point, so this method
  /// can remove only a part of it. For example, only the skin tone modifier of `'👍🏽'`.
  /// The position must be in range 0 up to length - 1, otherwise
  /// `PowerAuthErrorCode.wrongParameter` is reported.
  Future<int> removeCodePointAt(int position) => _enqueue(() async {
    _validatePosition(position);
    return _handle.withObjectId((id) => _platform.removeCharacterAt(id, position));
  });

  /// Removes the last code point and returns the remaining number of code points
  /// stored in the password.
  ///
  /// This method works the same as [removeLastCodePoint].
  @Deprecated('Use removeLastCodePoint() instead. This method will be removed in a future major version.')
  Future<int> removeLastCharacter() => removeLastCodePoint();

  /// Removes the last code point and returns the remaining number of code points
  /// stored in the password. If the password is empty, nothing is removed.
  ///
  /// A visible character can consist of more than one code point, so this method
  /// can remove only a part of it. For example, only the skin tone modifier of `'👍🏽'`.
  Future<int> removeLastCodePoint() => _enqueue(() => _handle.withObjectId((id) => _platform.removeLastCharacter(id)));

  /// Compares this password with another [PowerAuthPassword].
  Future<bool> isEqualTo(PowerAuthPassword other) {
    // Wait only for the operations that were already queued in the other password,
    // otherwise two passwords compared with each other at the same time would deadlock.
    final otherTail = other._tail;
    return _enqueue(() async {
      await otherTail;
      final id1 = await _handle.getObjectId();
      final id2 = await other._handle.getObjectId();

      return _platform.isEqualTo(id1, id2);
    });
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    // Start immediately when no operation is pending, so the native call is made
    // in the same order as calls to other objects, such as PowerAuth configuration.
    final result = _pendingCount == 0 ? Future.sync(operation) : _tail.then((_) => operation());
    _pendingCount++;
    _tail = result.then<void>((_) {}, onError: (_) {}).whenComplete(() => _pendingCount--);
    return result;
  }

  Future<int> _addCodePoint(int codePoint) async {
    _validateCodePoint(codePoint);
    return _handle.withObjectId((id) => _platform.addCharacter(id, codePoint));
  }

  Future<int> _insertCodePoint(int codePoint, int at) async {
    _validateCodePoint(codePoint);
    _validatePosition(at);
    return _handle.withObjectId((id) => _platform.insertCharacter(id, codePoint, at));
  }

  Runes _getCodePoints(String character) {
    if (character.isEmpty) {
      throw PowerAuthException(
        code: PowerAuthErrorCode.wrongParameter,
        message: 'String must not be empty',
      );
    }

    return character.runes;
  }

  void _validateCodePoint(int codePoint) {
    if (codePoint < 0 || codePoint > 0x10FFFF) {
      throw PowerAuthException(
        code: PowerAuthErrorCode.wrongParameter,
        message: 'Code point must be in range 0 up to 0x10FFFF',
      );
    }
  }

  void _validatePosition(int position) {
    // Native code accepts only 32-bit positions.
    if (position < 0 || position > 0x7FFFFFFF) {
      throw PowerAuthException(
        code: PowerAuthErrorCode.wrongParameter,
        message: 'Position is out of range',
      );
    }
  }

  /// Internal method for serialization.
  /// Ensures the native object is initialized.
  @internal
  Future<Map<String, dynamic>> toRawPasswordMap() {
    return _enqueue(() => _handle.withObjectId((id) async {
      return {
        'objectId': id,
        'destroyOnUse': destroyOnUse,
        'ownerId': powerAuthInstanceId,
        'autoreleaseTime': autoReleaseTimeMillis
      }..removeWhere((key, value) => value == null);
    }));
  }
}
