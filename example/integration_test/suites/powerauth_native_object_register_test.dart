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

import 'package:flutter_test/flutter_test.dart';

import '../utils/helper_functions.dart';

main() {
  group('Native object register tests', () {
    late IntegrationHelper helper;
    late PowerAuth sdk;

    late String tag;

    setUp(() async {
      sdk = PowerAuth(IntegrationHelper.randomString(30));
      helper = IntegrationHelper(sdk);
      await helper.configure();

      // Ensure that the native object register is cleared before each test
      tag = "tag_${IntegrationHelper.randomString(7)}";
    });

    tearDown(() async {
      await helper.cleanup();
    });

    test('simpleTest', () async {
      expect(await (await NativeObjectRegister.countObjects(tag)).total, 0);
    });

    test('testDumpingRegisteredObjects', () async {
      final dataId1 = await NativeObjectRegister.createObject(
        NativeObjectCmdData(
          objectType: NativeObjectType.data,
          objectTag: tag,
          releasePolicy: ['expire 400'],
        ),
      );
      final dataId2 = await NativeObjectRegister.createObject(
        NativeObjectCmdData(
          objectType: NativeObjectType.secureData,
          objectTag: tag,
          releasePolicy: ['keepAlive 200'],
        ),
      );
      final dataId3 = await NativeObjectRegister.createObject(
        NativeObjectCmdData(
          objectType: NativeObjectType.secureData,
          objectTag: tag,
          releasePolicy: ['afterUse 2'],
        ),
      );

      print("Using IDs '$dataId1', '$dataId2', '$dataId3'");

      expect(
        await NativeObjectRegister.findObject(dataId1, NativeObjectType.data),
        true,
      );
      expect(
        await NativeObjectRegister.findObject(
          dataId2,
          NativeObjectType.secureData,
        ),
        true,
      );
      expect(
        await NativeObjectRegister.findObject(
          dataId3,
          NativeObjectType.secureData,
        ),
        true,
      );

      await NativeObjectRegister.useObject(
        dataId3,
        NativeObjectType.secureData,
      );
      expect(
        await NativeObjectRegister.findObject(
          dataId3,
          NativeObjectType.secureData,
        ),
        true,
      );
      await NativeObjectRegister.useObject(
        dataId3,
        NativeObjectType.secureData,
      );
      expect(
        await NativeObjectRegister.findObject(
          dataId3,
          NativeObjectType.secureData,
        ),
        false,
      );

      await PowerAuthDebug.dumpNativeObjects(instanceId: tag);
    });

    test('testObjectsExpiration', () async {
      final dataId1 = await NativeObjectRegister.createObject(
        NativeObjectCmdData(
          objectType: NativeObjectType.data,
          objectTag: tag,
          releasePolicy: ['expire 400', 'afterUse 1'],
        ),
      );
      final dataId2 = await NativeObjectRegister.createObject(
        NativeObjectCmdData(
          objectType: NativeObjectType.secureData,
          objectTag: tag,
          releasePolicy: ['expire 200', 'keepAlive 400'],
        ),
      );

      print("Using IDs '$dataId1', '$dataId2'");

      expect(
        await NativeObjectRegister.findObject(dataId1, NativeObjectType.data),
        true,
      );
      expect(
        await NativeObjectRegister.findObject(
          dataId2,
          NativeObjectType.secureData,
        ),
        true,
      );
      expect((await NativeObjectRegister.countObjects(tag)).valid, 2);

      await sleep(200);

      expect(
        await NativeObjectRegister.findObject(dataId1, NativeObjectType.data),
        true,
      );
      expect(
        await NativeObjectRegister.findObject(
          dataId2,
          NativeObjectType.secureData,
        ),
        false,
      );
      expect((await NativeObjectRegister.countObjects(tag)).valid, 1);

      await sleep(200);

      expect(
        await NativeObjectRegister.findObject(dataId1, NativeObjectType.data),
        false,
      );
      expect(
        await NativeObjectRegister.findObject(
          dataId2,
          NativeObjectType.secureData,
        ),
        false,
      );
      expect((await NativeObjectRegister.countObjects(tag)).valid, 0);
    });

    test('testUsageCount', () async {
      final dataId1 = await NativeObjectRegister.createObject(
        NativeObjectCmdData(
          objectType: NativeObjectType.data,
          objectTag: tag,
          releasePolicy: ['afterUse 1'],
        ),
      );
      final dataId2 = await NativeObjectRegister.createObject(
        NativeObjectCmdData(
          objectType: NativeObjectType.data,
          objectTag: tag,
          releasePolicy: ['expire 500', 'afterUse 2'],
        ),
      );
      final dataId3 = await NativeObjectRegister.createObject(
        NativeObjectCmdData(
          objectType: NativeObjectType.data,
          objectTag: tag,
          releasePolicy: ['keepAlive 200', 'afterUse 4'],
        ),
      );
      final dataId4 = await NativeObjectRegister.createObject(
        NativeObjectCmdData(
          objectType: NativeObjectType.data,
          objectTag: tag,
          releasePolicy: ['keepAlive 200', 'afterUse 4'],
        ),
      );

      print("Using IDs '$dataId1', '$dataId2', '$dataId3', '$dataId4'");

      // Initial expectation
      expect(
        await NativeObjectRegister.findObject(dataId1, NativeObjectType.data),
        true,
      );
      expect(
        await NativeObjectRegister.findObject(dataId2, NativeObjectType.data),
        true,
      );
      expect(
        await NativeObjectRegister.findObject(dataId3, NativeObjectType.data),
        true,
      );
      expect(
        await NativeObjectRegister.findObject(dataId4, NativeObjectType.data),
        true,
      );
      expect((await NativeObjectRegister.countObjects(tag)).valid, 4);

      await sleep(100);

      // After 100ms everything should be still valid
      expect((await NativeObjectRegister.countObjects(tag)).valid, 4);

      // use dataId4, this will extend its lifetime
      expect(
        await NativeObjectRegister.useObject(dataId4, NativeObjectType.data),
        true,
      );

      await sleep(100);

      // After next 100ms, dataId3 will be removed
      expect(
        await NativeObjectRegister.findObject(dataId1, NativeObjectType.data),
        true,
      );
      expect(
        await NativeObjectRegister.findObject(dataId2, NativeObjectType.data),
        true,
      );
      expect(
        await NativeObjectRegister.findObject(dataId3, NativeObjectType.data),
        false,
      );
      expect(
        await NativeObjectRegister.findObject(dataId4, NativeObjectType.data),
        true,
      );

      // Now use dataId2 for 1st time
      expect(
        await NativeObjectRegister.useObject(dataId2, NativeObjectType.data),
        true,
      );

      expect(
        await NativeObjectRegister.findObject(dataId1, NativeObjectType.data),
        true,
      );
      expect(
        await NativeObjectRegister.findObject(dataId2, NativeObjectType.data),
        true,
      );
      expect(
        await NativeObjectRegister.findObject(dataId3, NativeObjectType.data),
        false,
      );
      expect(
        await NativeObjectRegister.findObject(dataId4, NativeObjectType.data),
        true,
      );

      await sleep(100);

      // Now use dataId2 for 2nd time, it should be released now
      // Also dataId4 is now released
      expect(
        await NativeObjectRegister.useObject(dataId2, NativeObjectType.data),
        true,
      );

      expect(
        await NativeObjectRegister.findObject(dataId1, NativeObjectType.data),
        true,
      );
      expect(
        await NativeObjectRegister.findObject(dataId2, NativeObjectType.data),
        false,
      );
      expect(
        await NativeObjectRegister.findObject(dataId3, NativeObjectType.data),
        false,
      );
      expect(
        await NativeObjectRegister.findObject(dataId4, NativeObjectType.data),
        false,
      );

      // And finally, use dataId4, to release it
      expect(
        await NativeObjectRegister.useObject(dataId1, NativeObjectType.data),
        true,
      );

      expect(
        await NativeObjectRegister.findObject(dataId1, NativeObjectType.data),
        false,
      );
      expect(
        await NativeObjectRegister.findObject(dataId2, NativeObjectType.data),
        false,
      );
      expect(
        await NativeObjectRegister.findObject(dataId3, NativeObjectType.data),
        false,
      );
      expect(
        await NativeObjectRegister.findObject(dataId4, NativeObjectType.data),
        false,
      );
      expect((await NativeObjectRegister.countObjects(tag)).valid, 0);
    });

    test('testTouchObject', () async {
      final dataId1 = await NativeObjectRegister.createObject(
        NativeObjectCmdData(
          objectType: NativeObjectType.data,
          objectTag: tag,
          releasePolicy: ['keepAlive 100', 'afterUse 4'],
        ),
      );
      final dataId2 = await NativeObjectRegister.createObject(
        NativeObjectCmdData(
          objectType: NativeObjectType.data,
          objectTag: tag,
          releasePolicy: ['keepAlive 100', 'afterUse 4'],
        ),
      );

      print("Using IDs '$dataId1', '$dataId2'");
      expect(
        await NativeObjectRegister.findObject(dataId1, NativeObjectType.data),
        true,
      );
      expect(
        await NativeObjectRegister.findObject(dataId2, NativeObjectType.data),
        true,
      );
      expect((await NativeObjectRegister.countObjects(tag)).valid, 2);

      await sleep(50);
      expect(
        await NativeObjectRegister.touchObject(dataId2, NativeObjectType.data),
        true,
      );

      await sleep(50);
      expect(
        await NativeObjectRegister.findObject(dataId1, NativeObjectType.data),
        false,
      );
      expect(
        await NativeObjectRegister.findObject(dataId2, NativeObjectType.data),
        true,
      );
      await sleep(50);
      expect(
        await NativeObjectRegister.findObject(dataId1, NativeObjectType.data),
        false,
      );
      expect(
        await NativeObjectRegister.findObject(dataId2, NativeObjectType.data),
        false,
      );
      expect((await NativeObjectRegister.countObjects(tag)).valid, 0);
    });

    test('testManualRelease', () async {
      final dataId1 = await NativeObjectRegister.createObject(
        NativeObjectCmdData(
          objectType: NativeObjectType.data,
          objectTag: tag,
          releasePolicy: ['afterUse 1', 'manual'],
        ),
      );
      final dataId2 = await NativeObjectRegister.createObject(
        NativeObjectCmdData(
          objectType: NativeObjectType.data,
          objectTag: tag,
          releasePolicy: ['manual', 'expire 100', 'afterUse 2'],
        ),
      );
      final dataId3 = await NativeObjectRegister.createObject(
        NativeObjectCmdData(
          objectType: NativeObjectType.data,
          objectTag: tag,
          releasePolicy: ['keepAlive 100', 'afterUse 4', 'manual'],
        ),
      );
      final dataId4 = await NativeObjectRegister.createObject(
        NativeObjectCmdData(
          objectType: NativeObjectType.data,
          objectTag: tag,
          releasePolicy: ['manual'],
        ),
      );

      print("Using IDs '$dataId1', '$dataId2', '$dataId3', '$dataId4'");

      // All manual objects must be in the register for the whole time 
      expect(
        await NativeObjectRegister.findObject(dataId1, NativeObjectType.data),
        true,
      );
      expect(
        await NativeObjectRegister.findObject(dataId2, NativeObjectType.data),
        true,
      );
      expect(
        await NativeObjectRegister.findObject(dataId3, NativeObjectType.data),
        true,
      );
      expect(
        await NativeObjectRegister.findObject(dataId4, NativeObjectType.data),
        true,
      );
      expect((await NativeObjectRegister.countObjects(tag)).valid, 4);

      expect(
        await NativeObjectRegister.useObject(dataId1, NativeObjectType.data),
        true,
      );
      expect(
        await NativeObjectRegister.findObject(dataId1, NativeObjectType.data),
        true,
      );

      await sleep(110);

      expect(
        await NativeObjectRegister.findObject(dataId1, NativeObjectType.data),
        true,
      );
      expect(
        await NativeObjectRegister.findObject(dataId2, NativeObjectType.data),
        true,
      );
      expect(
        await NativeObjectRegister.findObject(dataId3, NativeObjectType.data),
        true,
      );
      expect(
        await NativeObjectRegister.findObject(dataId4, NativeObjectType.data),
        true,
      );

      // Now remove objects manually
      expect(
        await NativeObjectRegister.removeObject(dataId1, NativeObjectType.data),
        true,
      );
      expect(
        await NativeObjectRegister.removeObject(dataId2, NativeObjectType.data),
        true,
      );
      expect(
        await NativeObjectRegister.removeObject(dataId3, NativeObjectType.data),
        true,
      );
      expect(
        await NativeObjectRegister.removeObject(dataId4, NativeObjectType.data),
        true,
      );

      expect((await NativeObjectRegister.countObjects(tag)).valid, 0);
    });

    test('testAccessWrongObjectType', () async {
      final id1 = await NativeObjectRegister.createObject(
        NativeObjectCmdData(
          objectType: NativeObjectType.data,
          objectTag: tag,
          releasePolicy: ['expire 200'],
        ),
      );
      final id2 = await NativeObjectRegister.createObject(
        NativeObjectCmdData(
          objectType: NativeObjectType.number,
          objectTag: tag,
          releasePolicy: ['expire 200'],
        ),
      );

      print("Using IDs '$id1', '$id2''");

      // Correct
      expect(
        await NativeObjectRegister.findObject(id1, NativeObjectType.data),
        true,
      );
      expect(
        await NativeObjectRegister.findObject(id2, NativeObjectType.number),
        true,
      );
      // Incorrect type in find
      expect(
        await NativeObjectRegister.findObject(id1, NativeObjectType.number),
        false,
      );
      // Incorrect type in use
      expect(
        await NativeObjectRegister.findObject(id2, NativeObjectType.data),
        false,
      );
      expect(
        await NativeObjectRegister.useObject(id1, NativeObjectType.number),
        false,
      );
      // Incorrect type in remove
      expect(
        await NativeObjectRegister.useObject(id2, NativeObjectType.data),
        false,
      );
      expect(
        await NativeObjectRegister.removeObject(id1, NativeObjectType.number),
        false,
      );
      expect(
        await NativeObjectRegister.removeObject(id2, NativeObjectType.data),
        false,
      );

      // Objects still should be in register
      expect((await NativeObjectRegister.countObjects(tag)).valid, 2);
      // Correct type in remove
      expect(
        await NativeObjectRegister.removeObject(id1, NativeObjectType.data),
        true,
      );
      expect(
        await NativeObjectRegister.removeObject(id2, NativeObjectType.number),
        true,
      );

      // After cleanup, count should be 0
      expect((await NativeObjectRegister.countObjects(tag)).valid, 0);
    });
  });
}
