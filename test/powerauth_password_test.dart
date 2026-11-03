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

// The deprecated addCharacter(), insertCharacter(), removeCharacterAt() and removeLastCharacter()
// are still covered by tests.
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/src/powerauth_native_object_register/powerauth_native_object_register_platform_interface.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/src/powerauth_password/powerauth_password_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

class _PasswordPlatform extends PowerAuthPasswordPlatform {
  final List<int> codePoints = [];
  int initializeCount = 0;
  int? failAtLength;

  @override
  Future<String> initialize({
    required bool destroyOnUse,
    String? powerAuthInstanceId,
    int? autoReleaseTimeMillis,
  }) async {
    initializeCount++;
    return 'password';
  }

  @override
  Future<int> length(String objectId) async => codePoints.length;

  @override
  Future<int> addCharacter(String objectId, int character) async {
    if (codePoints.length == failAtLength) {
      throw PowerAuthException(code: PowerAuthErrorCode.invalidNativeObject);
    }
    codePoints.add(character);
    return codePoints.length;
  }

  @override
  Future<int> removeCharacterAt(String objectId, int position) async {
    if (position < 0 || position >= codePoints.length) {
      throw PowerAuthException(code: PowerAuthErrorCode.wrongParameter);
    }
    codePoints.removeAt(position);
    return codePoints.length;
  }

  @override
  Future<bool> isEqualTo(String objectId, String otherObjectId) async => objectId == otherObjectId;

  @override
  Future<int> removeLastCharacter(String objectId) async {
    if (codePoints.isNotEmpty) {
      codePoints.removeLast();
    }
    return codePoints.length;
  }

  @override
  Future<int> insertCharacter(String objectId, int character, int at) async {
    if (at < 0 || at > codePoints.length) {
      throw PowerAuthException(code: PowerAuthErrorCode.wrongParameter);
    }
    codePoints.insert(at, character);
    return codePoints.length;
  }
}

class _NativeObjectRegisterPlatform extends NativeObjectRegisterPlatform {
  final releasedObjectIds = <String>[];

  @override
  Future<void> releaseNativeObject(String objectId) async {
    releasedObjectIds.add(objectId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PowerAuthPasswordPlatform originalPlatform;
  late NativeObjectRegisterPlatform originalRegisterPlatform;
  late _PasswordPlatform platform;
  late _NativeObjectRegisterPlatform registerPlatform;

  setUp(() {
    originalPlatform = PowerAuthPasswordPlatform.instance;
    originalRegisterPlatform = NativeObjectRegisterPlatform.instance;
    platform = _PasswordPlatform();
    PowerAuthPasswordPlatform.instance = platform;
    registerPlatform = _NativeObjectRegisterPlatform();
    NativeObjectRegisterPlatform.instance = registerPlatform;
  });

  tearDown(() {
    PowerAuthPasswordPlatform.instance = originalPlatform;
    NativeObjectRegisterPlatform.instance = originalRegisterPlatform;
  });

  Matcher throwsWrongParameter() => throwsA(
    isA<PowerAuthException>().having(
      (e) => e.code,
      'code',
      PowerAuthErrorCode.wrongParameter,
    ),
  );

  test('addCharacter adds every code point', () async {
    final password = PowerAuthPassword();

    expect(await password.addCharacter('a'), 1);
    expect(await password.addCharacter('👍🏿'), 3);
    expect(await password.addCharacter('e\u0301'), 5);
    expect(platform.codePoints, [0x61, 0x1F44D, 0x1F3FF, 0x65, 0x301]);
  });

  test('addCodePoints adds every code point', () async {
    final password = PowerAuthPassword();

    expect(await password.addCodePoints('a👍🏿'), 3);
    expect(await password.addCodePoints(''), 3);
    expect(await password.addCodePoints('e\u0301'), 5);
    expect(platform.codePoints, [0x61, 0x1F44D, 0x1F3FF, 0x65, 0x301]);
  });

  test('fromString with empty string does not allocate the native password', () async {
    await PowerAuthPassword.fromString('');

    expect(platform.initializeCount, 0);
  });

  test('fromString releases the native password if adding fails', () async {
    platform.failAtLength = 2;

    await expectLater(PowerAuthPassword.fromString('abcd'), throwsA(isA<PowerAuthException>()));
    expect(registerPlatform.releasedObjectIds, ['password']);
  });

  test('invalid input does not allocate the native password', () async {
    final password = PowerAuthPassword();

    await expectLater(password.addCharacter(''), throwsWrongParameter());
    await expectLater(password.insertCharacter('', 0), throwsWrongParameter());
    await expectLater(password.insertCharacter('A', -1), throwsWrongParameter());
    await expectLater(password.addCodePoint(0x110000), throwsWrongParameter());
    await expectLater(password.insertCodePoint(-1, 0), throwsWrongParameter());
    await expectLater(password.insertCodePoint(0x41, -1), throwsWrongParameter());
    await expectLater(password.removeCodePointAt(-1), throwsWrongParameter());
    expect(await password.addCodePoints(''), 0);
    expect(platform.initializeCount, 0);
  });

  test('insertCharacter inserts every code point in order', () async {
    final password = PowerAuthPassword();

    expect(await password.insertCharacter('ab', 0), 2);
    expect(await password.insertCharacter('👍🏿', 1), 4);
    expect(platform.codePoints, [0x61, 0x1F44D, 0x1F3FF, 0x62]);
  });

  test('addCharacter and fromString store the same code points', () async {
    const value = 'a👍🏿e\u0301';
    await PowerAuthPassword.fromString(value);
    final fromString = List.of(platform.codePoints);
    platform.codePoints.clear();

    await PowerAuthPassword().addCharacter(value);

    expect(platform.codePoints, fromString);
  });

  test('code points are not normalized', () async {
    await PowerAuthPassword().addCharacter('e\u0301');
    await PowerAuthPassword().addCharacter('\u00E9');

    expect(platform.codePoints, [0x65, 0x301, 0xE9]);
  });

  test('empty string is rejected', () async {
    final password = PowerAuthPassword();

    await expectLater(password.addCharacter(''), throwsWrongParameter());
    await expectLater(password.insertCharacter('', 0), throwsWrongParameter());
    expect(platform.codePoints, isEmpty);
  });

  test('insertCharacter rejects position out of range', () async {
    final password = PowerAuthPassword();

    await expectLater(password.insertCharacter('👍🏿', 1), throwsWrongParameter());
    expect(platform.codePoints, isEmpty);
  });

  test('code point out of range is rejected', () async {
    final password = PowerAuthPassword();

    for (final codePoint in [-1, 0x110000, 0x100000000]) {
      await expectLater(password.addCodePoint(codePoint), throwsWrongParameter());
      await expectLater(password.insertCodePoint(codePoint, 0), throwsWrongParameter());
    }
    expect(await password.addCodePoint(0x10FFFF), 1);
    expect(await password.insertCodePoint(0, 0), 2);
    expect(platform.codePoints, [0, 0x10FFFF]);
  });

  test('released password reports invalidNativeObject before invalid input', () async {
    final password = PowerAuthPassword();
    await password.addCodePoint(0x61);
    await password.release();

    final throwsInvalidNativeObject = throwsA(
      isA<PowerAuthException>().having((e) => e.code, 'code', PowerAuthErrorCode.invalidNativeObject),
    );
    await expectLater(password.addCodePoint(0x110000), throwsInvalidNativeObject);
    await expectLater(password.insertCodePoint(-1, 0), throwsInvalidNativeObject);
    await expectLater(password.removeCodePointAt(-1), throwsInvalidNativeObject);
    await expectLater(password.addCharacter(''), throwsInvalidNativeObject);
    await expectLater(password.insertCharacter('', 0), throwsInvalidNativeObject);
    await expectLater(password.addCodePoints(''), throwsInvalidNativeObject);
  });

  test('position out of 32-bit range is rejected', () async {
    final password = PowerAuthPassword();

    await expectLater(password.insertCodePoint(0x41, 0x80000000), throwsWrongParameter());
    await expectLater(password.insertCharacter('A', 0x80000000), throwsWrongParameter());
    await expectLater(password.removeCodePointAt(0x80000000), throwsWrongParameter());
    expect(platform.codePoints, isEmpty);
  });

  test('deprecated removal methods remove one code point', () async {
    final password = PowerAuthPassword();
    await password.addCharacter('a👍🏿b');

    expect(await password.removeCharacterAt(0), 3);
    expect(await password.removeLastCharacter(), 2);
    expect(platform.codePoints, [0x1F44D, 0x1F3FF]);
    await expectLater(password.removeCharacterAt(0x80000000), throwsWrongParameter());
  });
}
