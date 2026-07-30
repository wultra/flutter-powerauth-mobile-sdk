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
import 'package:flutter_powerauth_mobile_sdk_plugin/src/powerauth_native_object_register/powerauth_native_object_register_platform_interface.dart';
import '../utils/integration_helper.dart';
import '../utils/object_cleanup_helper.dart';

import '../utils/native_test.dart';

import '../utils/helper_functions.dart';

main() {
  group('Password tests', () {
    late ObjectCleanupHelper cleanupHelper;
    late IntegrationHelper helper;
    late PowerAuth sdk;
    late String sdkInstanceId;

    setUp(() async {
      cleanupHelper = ObjectCleanupHelper();

      sdkInstanceId = IntegrationHelper.randomString(30);
      sdk = PowerAuth(sdkInstanceId);
      helper = IntegrationHelper(sdk);
      await helper.configure();
      await NativeObjectRegister.setCleanupPeriod(100);
    });

    tearDown(() async {
      await NativeObjectRegister.setCleanupPeriod(10000);
      await helper.cleanup();
      await cleanupHelper.dispose();
    });

    bool isPasswordObject(NativeObjectInfo object) =>
        object.className.contains('Password');

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
        powerAuthInstanceId: sdkInstanceId,
        autoReleaseTimeMillis: 1000,
      );
      final p2 = PowerAuthPassword(
        destroyOnUse: false,
        powerAuthInstanceId: sdkInstanceId,
        autoReleaseTimeMillis: 100,
      );
      cleanupHelper.cleanup.addAll([p1, p2]);

      final before = await NativeObjectRegister.debugDump(sdkInstanceId);
      final beforeIds = before.map((object) => object.id).toSet();

      // Construction is lazy, so no password exists before the first operation.
      expect(
        (await NativeObjectRegister.debugDump(
          sdkInstanceId,
        )).where(isPasswordObject).map((object) => object.id).toSet(),
        before.where(isPasswordObject).map((object) => object.id).toSet(),
      );

      expect(await p1.isEmpty(), true, reason: "1");
      final p1Info = await waitForNewNativeObject(
        instanceId: sdkInstanceId,
        previousIds: beforeIds,
        matches: isPasswordObject,
      );
      expect(await p2.length(), 0);
      final p2Info = await waitForNewNativeObject(
        instanceId: sdkInstanceId,
        previousIds: {...beforeIds, p1Info.id},
        matches: isPasswordObject,
      );

      expect(
        (await NativeObjectRegister.debugDump(sdkInstanceId))
            .where((object) => object.id == p1Info.id || object.id == p2Info.id)
            .length,
        2,
      );

      await p1.addCodePoint(48);
      await waitForNativeObjects(
        instanceId: sdkInstanceId,
        predicate:
            (objects) =>
                objects.any((object) => object.id == p1Info.id) &&
                objects.every((object) => object.id != p2Info.id),
      );

      expect(await p1.isEmpty(), false);
      await expectLater(
        p2.isEmpty(),
        throwsPowerAuthCode(PowerAuthErrorCode.invalidNativeObject),
      );

      await waitForNativeObjects(
        instanceId: sdkInstanceId,
        predicate:
            (objects) => objects.every((object) => object.id != p1Info.id),
      );
      await expectLater(
        p1.isEmpty(),
        throwsPowerAuthCode(PowerAuthErrorCode.invalidNativeObject),
      );
    });

    test('testReleaseAfterUse', () async {
      final p1 = PowerAuthPassword(
        destroyOnUse: true,
        powerAuthInstanceId: sdkInstanceId,
        autoReleaseTimeMillis: 100,
      );
      final p2 = PowerAuthPassword(
        destroyOnUse: true,
        powerAuthInstanceId: sdkInstanceId,
        autoReleaseTimeMillis: 100,
      );
      cleanupHelper.cleanup.addAll([p1, p2]);

      final beforeIds =
          (await NativeObjectRegister.debugDump(
            sdkInstanceId,
          )).map((object) => object.id).toSet();
      await p1.addCodePoint(48);
      expect(await p1.isEmpty(), false);
      final p1Info = await waitForNewNativeObject(
        instanceId: sdkInstanceId,
        previousIds: beforeIds,
        matches: isPasswordObject,
      );
      expect(await p2.isEmpty(), true);
      final p2Info = await waitForNewNativeObject(
        instanceId: sdkInstanceId,
        previousIds: {...beforeIds, p1Info.id},
        matches: isPasswordObject,
      );

      expect(
        await NativeObjectRegister.useObject(
          p1Info.id,
          NativeObjectType.password,
        ),
        true,
      );
      expect(
        await NativeObjectRegister.useObject(
          p2Info.id,
          NativeObjectType.password,
        ),
        true,
      );

      // Both object should be invalid when used once
      await expectLater(
        p1.isEmpty(),
        throwsPowerAuthCode(PowerAuthErrorCode.invalidNativeObject),
      );
      await expectLater(
        p2.isEmpty(),
        throwsPowerAuthCode(PowerAuthErrorCode.invalidNativeObject),
      );

      final invalidObjects = await NativeObjectRegister.debugDump(
        sdkInstanceId,
      );
      expect(
        invalidObjects
            .where((object) => object.id == p1Info.id || object.id == p2Info.id)
            .every((object) => object.isValid == false),
        isTrue,
      );
      await waitForNativeObjects(
        instanceId: sdkInstanceId,
        predicate:
            (objects) => objects.every(
              (object) => object.id != p1Info.id && object.id != p2Info.id,
            ),
      );
    });

    test('testManualRelease', () async {
      var p1 = PowerAuthPassword(
        destroyOnUse: false,
        powerAuthInstanceId: sdkInstanceId,
        autoReleaseTimeMillis: 1200,
      );
      var p2 = PowerAuthPassword(
        destroyOnUse: true,
        powerAuthInstanceId: sdkInstanceId,
        autoReleaseTimeMillis: 1200,
      );
      cleanupHelper.cleanup.addAll([p1, p2]);

      // Native objects are no created yet
      await p1.release();
      await p2.release();

      await p1.addCodePoint(48);
      expect(await p1.isEmpty(), false);
      expect(await p2.isEmpty(), true);

      final passwordIds =
          (await NativeObjectRegister.debugDump(
            sdkInstanceId,
          )).where(isPasswordObject).map((object) => object.id).toSet();
      expect(passwordIds.length, 2);

      // Now manually release passwords
      await p1.release();
      await p2.release();
      await waitForNativeObjects(
        instanceId: sdkInstanceId,
        predicate:
            (objects) =>
                objects.every((object) => !passwordIds.contains(object.id)),
      );

      // Both passwords should be released and throw on access
      await expectLater(
        p1.addCharacter('1'),
        throwsPowerAuthCode(PowerAuthErrorCode.invalidNativeObject),
      );
      await expectLater(
        p2.addCharacter('1'),
        throwsPowerAuthCode(PowerAuthErrorCode.invalidNativeObject),
      );

      // Instantiate again
      p1 = PowerAuthPassword(
        destroyOnUse: false,
        powerAuthInstanceId: sdkInstanceId,
        autoReleaseTimeMillis: 1200,
      );
      p2 = PowerAuthPassword(
        destroyOnUse: true,
        powerAuthInstanceId: sdkInstanceId,
        autoReleaseTimeMillis: 1200,
      );
      cleanupHelper.cleanup.addAll([p1, p2]);

      await p1.addCodePoint(48);
      expect(await p1.isEmpty(), false);
      expect(await p2.isEmpty(), true);
      final repeatedReleaseIds =
          (await NativeObjectRegister.debugDump(
            sdkInstanceId,
          )).where(isPasswordObject).map((object) => object.id).toSet();
      expect(repeatedReleaseIds.length, 2);

      // Now release for multiple times, to make sure that function doesn't fail
      await p1.release();
      await p2.release();
      await p1.release();
      await p2.release();
      await waitForNativeObjects(
        instanceId: sdkInstanceId,
        predicate:
            (objects) => objects.every(
              (object) => !repeatedReleaseIds.contains(object.id),
            ),
      );
    });

    test('testGlobalRelease', () async {
      final config = await sdk.configuration;

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

      final ownedObjects = await NativeObjectRegister.debugDump(
        powerAuthInstanceId,
      );
      final passwordIds =
          ownedObjects
              .where(isPasswordObject)
              .map((object) => object.id)
              .toSet();
      expect(passwordIds.length, 2);

      // Now deconfigure PA instance
      await powerAuth.deconfigure();

      // Both passwords should be released
      await waitForNativeObjects(
        instanceId: powerAuthInstanceId,
        predicate:
            (objects) =>
                objects.every((object) => !passwordIds.contains(object.id)),
      );

      // Both passwords should be invalid when accessed
      await expectLater(
        p1.isEmpty(),
        throwsPowerAuthCode(PowerAuthErrorCode.invalidNativeObject),
      );
      await expectLater(
        p2.length(),
        throwsPowerAuthCode(PowerAuthErrorCode.invalidNativeObject),
      );
    });
  });
}
