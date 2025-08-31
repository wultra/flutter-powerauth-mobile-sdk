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

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import '../utils/integration_helper.dart';
import '../utils/object_cleanup_helper.dart';

import 'package:flutter_test/flutter_test.dart';

import '../utils/helper_functions.dart';

main() {
  group('Password tests', () {
    late ObjectCleanupHelper cleanupHelper;
    late IntegrationHelper helper;
    late PowerAuth sdk;

    setUp(() async {
      cleanupHelper = ObjectCleanupHelper();

      sdk = PowerAuth(IntegrationHelper.randomString(30));
      helper = IntegrationHelper(sdk);
      await helper.configure();
    });

    tearDown(() async {
      await helper.cleanup();
      await cleanupHelper.dispose();
    });

    Future<PowerAuthPassword> importPassword(String password) {
      return PowerAuthPassword.fromString(password);
    }

    test('testAddCharacters', () async {
      var p1 = PowerAuthPassword();
      var p2 = PowerAuthPassword();
      var p3 = await PowerAuthPassword.fromString('0123');
      var pEmpty = PowerAuthPassword();
      cleanupHelper.cleanup.addAll([p1, p2, p3, pEmpty]);

      expect(await p1.isEmpty(), true, reason: "p1 is not empty");
      expect(await p2.isEmpty(), true, reason: "p2 is not empty");
      expect(
        await p1.isEqualTo(pEmpty),
        true,
        reason: "p1 is not equal to pEmpty",
      );
      expect(await p2.isEqualTo(pEmpty), true);
      expect(await p3.isEqualTo(pEmpty), false);

      expect(await p1.addCharacter('0'), 1);
      expect(await p2.addCodePoint(48), 1);
      expect(await p1.isEqualTo(pEmpty), false);
      expect(await p2.isEqualTo(pEmpty), false);
      expect(await p1.isEmpty(), false);
      expect(await p2.isEmpty(), false);

      expect(await p1.addCharacter('1'), 2);
      expect(await p2.addCodePoint(49), 2);
      expect(await p1.addCharacter('2'), 3);
      expect(await p2.addCodePoint(50), 3);
      expect(await p1.addCharacter('3'), 4);
      expect(await p2.addCodePoint(51), 4);

      expect(
        p1.addCodePoint(0x110000),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.wrongParameter,
          ),
        ),
      );

      expect(await p1.isEqualTo(p3), true);
      expect(await p2.isEqualTo(p3), true);
      expect(await p1.isEqualTo(p2), true);

      p1.clear();
      p2.clear();
      expect(await p1.isEqualTo(pEmpty), true);
      expect(await p2.isEqualTo(pEmpty), true);
    });

    test('testRemoveCharacters', () async {
      var p1 = await importPassword('Sk💀Ll');
      var t1 = await importPassword('k💀Ll');
      var t2 = await importPassword('k💀L');
      var t3 = await importPassword('kL');
      var t4 = await importPassword('k');
      cleanupHelper.cleanup.addAll([p1, t1, t2, t3, t4]);

      expect(
        p1.removeCharacterAt(-1),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.wrongParameter,
          ),
        ),
      );
      expect(
        p1.removeCharacterAt(5),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.wrongParameter,
          ),
        ),
      );

      expect(await p1.removeCharacterAt(0), 4);
      expect(await p1.isEqualTo(t1), true);
      expect(await p1.removeLastCharacter(), 3);
      expect(await p1.isEqualTo(t2), true);
      expect(await p1.removeCharacterAt(1), 2);
      expect(await p1.isEqualTo(t3), true);
      expect(await p1.removeCharacterAt(1), 1);
      expect(await p1.isEqualTo(t4), true);
      expect(await p1.removeCharacterAt(0), 0);
      expect(await p1.length(), 0);
      // Pop last should not fail
      expect(await p1.removeLastCharacter(), 0);

      expect(
        p1.removeCharacterAt(0),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.wrongParameter,
          ),
        ),
      );
    });

    test('testInsertCharacters', () async {
      var p1 = PowerAuthPassword();
      var p2 = await importPassword('Sk💀ll');
      cleanupHelper.cleanup.addAll([p1, p2]);

      expect(await p1.insertCharacter('l', 0), 1);
      expect(await p1.insertCharacter('l', 1), 2);
      expect(await p1.insertCharacter('S', 0), 3);
      expect(await p1.insertCharacter('k', 1), 4);
      expect(await p1.insertCodePoint(0x1F480, 2), 5);

      expect(
        p1.insertCharacter('X', -1),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.wrongParameter,
          ),
        ),
      );
      expect(
        p1.insertCharacter('X', 6),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.wrongParameter,
          ),
        ),
      );
      expect(
        p1.insertCodePoint(0x110000, 0),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.wrongParameter,
          ),
        ),
      );

      expect(await p1.isEqualTo(p2), true);
    });

    test('testUnicode', () async {
      var p1 = await importPassword('★🤣🤫🪘');
      var p2 = await importPassword('Sk💀ll');
      var p3 = PowerAuthPassword();
      var p4 = PowerAuthPassword();
      cleanupHelper.cleanup.addAll([p1, p2, p3, p4]);

      expect(await p1.length(), 4);
      expect(await p2.length(), 5);

      await p3.addCharacter('★');
      await p3.addCharacter('🤣🤫');
      await p3.addCharacter('🤫');
      await p3.addCharacter('🪘x');

      expect(await p3.length(), 4);

      await p4.addCodePoint(0x2605);
      await p4.addCodePoint(0x1F923);
      await p4.addCodePoint(0x1F92B);
      await p4.addCodePoint(0x1FA98);

      expect(await p4.length(), 4);

      expect(await p3.isEqualTo(p4), true);
      expect(await p3.isEqualTo(p1), true);
      expect(await p4.isEqualTo(p1), true);
    });

    test('testAutomaticCleanup', () async {
      final p1 = PowerAuthPassword(
        destroyOnUse: false,
        powerAuthInstanceId: null,
        autoReleaseTimeMillis: 100,
      );
      final p2 = PowerAuthPassword(
        destroyOnUse: false,
        powerAuthInstanceId: null,
        autoReleaseTimeMillis: 100,
      );
      cleanupHelper.cleanup.addAll([p1, p2]);

      // Right after construct the identifier is not set
      final id1AfterCreate = p1.objectId;
      final id2AfterCreate = p2.objectId;
      expect(id1AfterCreate, isNull);
      expect(id2AfterCreate, isNull);

      // We have to call at least some function to create underlying native object
      expect(await p1.isEmpty(), true, reason: "1");
      expect(await p2.length(), 0);

      // Now identifiers are available, but no cleanup was called
      final id1AfterAccess = p1.objectId!;
      final id2AfterAccess = p2.objectId!;
      expect(id1AfterAccess, isNotNull);
      expect(id2AfterAccess, isNotNull);

      // Wait for 50ms
      await sleep(50);
      // Both passwords should exist now
      expect(
        await NativeObjectRegister.findObject(
          id1AfterAccess,
          NativeObjectType.password,
        ),
        true,
        reason: "2",
      );
      // Access 1st password, to extend it's lifetime
      expect(
        await NativeObjectRegister.findObject(
          id2AfterAccess,
          NativeObjectType.password,
        ),
        true,
        reason: "3",
      );
      // Add a character to p1, to extend it's lifetime
      await p1.addCodePoint(48);
      // Wait for another 50ms, p2 should be released now
      await sleep(50);

      expect(
        await NativeObjectRegister.findObject(
          id1AfterAccess,
          NativeObjectType.password,
        ),
        true,
        reason: "4",
      );
      expect(
        await NativeObjectRegister.findObject(
          id2AfterAccess,
          NativeObjectType.password,
        ),
        false,
      );

      // native p2 is no longer valid, but its identifier is still set in JS object
      expect(p2.objectId, isNotNull);
      // Now extend p1 again
      expect(await p1.isEmpty(), false);
      // And access p2 again. Invalid native object should be thrown
      expect(
        p2.isEmpty(),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.invalidNativeObject,
          ),
        ),
      );

      // Wait for another 100ms, so both passwords will be released
      await sleep(100);

      expect(
        p1.isEmpty(),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.invalidNativeObject,
          ),
        ),
      );
    });

    test('testReleaseAfterUse', () async {
      final p1 = PowerAuthPassword(
        destroyOnUse: true,
        powerAuthInstanceId: null,
        autoReleaseTimeMillis: 100,
      );
      final p2 = PowerAuthPassword(
        destroyOnUse: true,
        powerAuthInstanceId: null,
        autoReleaseTimeMillis: 100,
      );
      cleanupHelper.cleanup.addAll([p1, p2]);

      await p1.addCodePoint(48);
      expect(await p1.isEmpty(), false);
      expect(await p2.isEmpty(), true);

      final id1AfterAccess = p1.objectId!;
      final id2AfterAccess = p2.objectId!;

      expect(
        await NativeObjectRegister.useObject(
          id1AfterAccess,
          NativeObjectType.password,
        ),
        true,
      );
      expect(
        await NativeObjectRegister.useObject(
          id2AfterAccess,
          NativeObjectType.password,
        ),
        true,
      );

      // Both object should be invalid when used once
      expect(
        p1.isEmpty(),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.invalidNativeObject,
          ),
        ),
      );
      expect(
        p2.isEmpty(),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.invalidNativeObject,
          ),
        ),
      );

      expect(
        await NativeObjectRegister.findObject(
          id1AfterAccess,
          NativeObjectType.password,
        ),
        false,
      );
      expect(
        await NativeObjectRegister.findObject(
          id2AfterAccess,
          NativeObjectType.password,
        ),
        false,
      );
    });

    test('testManualRelease', () async {
      var p1 = PowerAuthPassword(
        destroyOnUse: false,
        powerAuthInstanceId: null,
        autoReleaseTimeMillis: 100,
      );
      var p2 = PowerAuthPassword(
        destroyOnUse: true,
        powerAuthInstanceId: null,
        autoReleaseTimeMillis: 100,
      );
      cleanupHelper.cleanup.addAll([p1, p2]);

      // Native objects are no created yet
      await p1.release();
      await p2.release();

      await p1.addCodePoint(48);
      expect(await p1.isEmpty(), false);
      expect(await p2.isEmpty(), true);

      var id1AfterAccess = p1.objectId!;
      var id2AfterAccess = p2.objectId!;
      expect(id1AfterAccess, isNotNull);
      expect(id2AfterAccess, isNotNull);

      // Now manually release passwords
      await p1.release();
      await p2.release();

      // Both passwords should be released and throw on access
      expect(
        p1.addCharacter('1'),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.invalidNativeObject,
          ),
        ),
      );
      expect(
        p2.addCharacter('1'),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.invalidNativeObject,
          ),
        ),
      );

      // Instantiate again
      p1 = PowerAuthPassword(
        destroyOnUse: false,
        powerAuthInstanceId: null,
        autoReleaseTimeMillis: 100,
      );
      p2 = PowerAuthPassword(
        destroyOnUse: true,
        powerAuthInstanceId: null,
        autoReleaseTimeMillis: 100,
      );

      await p1.addCodePoint(48);
      expect(await p1.isEmpty(), false);
      expect(await p2.isEmpty(), true);

      // Now release for multiple times, to make sure that function doesn't fail
      await p1.release();
      await p2.release();
      await p1.release();
      await p2.release();
    });

    test('testGlobalRelease', () async {
      // Dummy values for PA configuration
      final config = PowerAuthConfiguration(
        configuration:
            "ARDUHbAKHLrIHQHyDWTQrA9SEDI7+KWhWMMnxWlNWpITDtsBAUEEJavzIZpq2wyAN5EOlGPK3XonwdDBWB1MHlEIGSPfahORoWH+wctzmJj8fSf/oO2Tbvy4ACC5sIu2HsCSz6+E8Q==",
        baseEndpointUrl: "http://localhost/wrong",
      );

      // Owner object represents an instance of PowerAuth class that typically owns various object types
      final powerAuthInstanceId = IntegrationHelper.randomString(10);
      final powerAuth = PowerAuth(powerAuthInstanceId);
      cleanupHelper.cleanup.add(powerAuth);

      // We can create passwords even in PA instance is not configured, but every call to password API will fail
      final p1 = PowerAuthPassword(
        destroyOnUse: false,
        powerAuthInstanceId: powerAuthInstanceId,
      );
      final p2 = PowerAuthPassword(
        destroyOnUse: true,
        powerAuthInstanceId: powerAuthInstanceId,
      );
      cleanupHelper.cleanup.addAll([p1, p2]);
      expect(p1.powerAuthInstanceId, powerAuthInstanceId);
      expect(p2.powerAuthInstanceId, powerAuthInstanceId);

      // PA instance is not configured yet, so the underlying password cannot be created.
      expect(
        p1.addCodePoint(48),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.instanceNotConfigured,
          ),
        ),
      );
      expect(
        p2.removeLastCharacter(),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.instanceNotConfigured,
          ),
        ),
      );

      // Configure PA instance
      await powerAuth.configure(configuration: config);

      // Now everything should work as expected
      await p1.addCodePoint(48);
      expect(await p1.isEmpty(), false);
      expect(await p2.isEmpty(), true);

      final id1AfterAccess = p1.objectId!;
      final id2AfterAccess = p2.objectId!;

      expect(
        await NativeObjectRegister.findObject(
          id1AfterAccess,
          NativeObjectType.password,
        ),
        true,
      );
      expect(
        await NativeObjectRegister.findObject(
          id2AfterAccess,
          NativeObjectType.password,
        ),
        true,
      );

      // Now deconfigure PA instance
      await powerAuth.deconfigure();

      // Both passwords should be released
      expect(
        await NativeObjectRegister.findObject(
          id1AfterAccess,
          NativeObjectType.password,
        ),
        false,
      );
      expect(
        await NativeObjectRegister.findObject(
          id2AfterAccess,
          NativeObjectType.password,
        ),
        false,
      );

      // Both passwords should be invalid when accessed
      expect(
        p1.isEmpty(),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.invalidNativeObject,
          ),
        ),
      );
      expect(
        p2.length(),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.invalidNativeObject,
          ),
        ),
      );
    });
  });
}
