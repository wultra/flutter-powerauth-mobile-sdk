import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/suites/test_suite.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/utils/integration_helper.dart';

class PowerauthNativeObjectRegisterTests extends TestSuite {

  @override
  List<Future<void> Function()> getTests() => [
    simpleTest,
    testDumpingRegisteredObjects,
    testObjectsExpiration,
    testUsageCount,
    testTouchObject,
    testManualRelease,
    testAccessWrongObjectType
  ];

  late String tag;

  @override
  Future<void> beforeEach() async {
    await super.beforeEach();
    // Ensure that the native object register is cleared before each test
    tag = "tag_${IntegrationHelper.randomString(7)}";
    print("Using tag '$tag'");
  }

  Future<void> simpleTest() async {
    await expect((await NativeObjectRegister.countObjects(tag)).total).toBe(0);
  }

  Future<void> testDumpingRegisteredObjects() async {

    final dataId1 = await NativeObjectRegister.createObject(NativeObjectCmdData(objectType: NativeObjectType.data, objectTag: tag, releasePolicy: ['expire 400']));
    final dataId2 = await NativeObjectRegister.createObject(NativeObjectCmdData(objectType: NativeObjectType.secureData, objectTag: tag, releasePolicy: ['keepAlive 200']));
    final dataId3 = await NativeObjectRegister.createObject(NativeObjectCmdData(objectType: NativeObjectType.secureData, objectTag: tag, releasePolicy: ['afterUse 2']));
    
    print("Using IDs '$dataId1', '$dataId2', '$dataId3'");

    await expect(NativeObjectRegister.findObject(dataId1, NativeObjectType.data)).toBe(true);
    await expect(NativeObjectRegister.findObject(dataId2, NativeObjectType.secureData)).toBe(true);
    await expect(NativeObjectRegister.findObject(dataId3, NativeObjectType.secureData)).toBe(true);

    await NativeObjectRegister.useObject(dataId3, NativeObjectType.secureData);
    await expect(NativeObjectRegister.findObject(dataId3, NativeObjectType.secureData)).toBe(true);
    await NativeObjectRegister.useObject(dataId3, NativeObjectType.secureData);
    await expect(NativeObjectRegister.findObject(dataId3, NativeObjectType.secureData)).toBe(false);

    await PowerAuthDebug.dumpNativeObjects(instanceId: tag);
  }

  Future<void> testObjectsExpiration() async {

    final dataId1 = await NativeObjectRegister.createObject(NativeObjectCmdData(objectType: NativeObjectType.data, objectTag: tag, releasePolicy: ['expire 400', 'afterUse 1']));
    final dataId2 = await NativeObjectRegister.createObject(NativeObjectCmdData(objectType: NativeObjectType.secureData, objectTag: tag, releasePolicy: ['expire 200', 'keepAlive 400']));
    
    print("Using IDs '$dataId1', '$dataId2'");

    await expect(NativeObjectRegister.findObject(dataId1, NativeObjectType.data)).toBe(true);
    await expect(NativeObjectRegister.findObject(dataId2, NativeObjectType.secureData)).toBe(true);
    await expect((await NativeObjectRegister.countObjects(tag)).valid).toBe(2);

    await sleep(200);

    await expect(NativeObjectRegister.findObject(dataId1, NativeObjectType.data)).toBe(true);
    await expect(NativeObjectRegister.findObject(dataId2, NativeObjectType.secureData)).toBe(false);
    await expect((await NativeObjectRegister.countObjects(tag)).valid).toBe(1);

    await sleep(200);

    await expect(NativeObjectRegister.findObject(dataId1, NativeObjectType.data)).toBe(false);
    await expect(NativeObjectRegister.findObject(dataId2, NativeObjectType.secureData)).toBe(false);
    await expect((await NativeObjectRegister.countObjects(tag)).valid).toBe(0);
  }

  Future<void> testUsageCount() async {

    final dataId1 = await NativeObjectRegister.createObject(NativeObjectCmdData(objectType: NativeObjectType.data, objectTag: tag, releasePolicy: ['afterUse 1']));
    final dataId2 = await NativeObjectRegister.createObject(NativeObjectCmdData(objectType: NativeObjectType.data, objectTag: tag, releasePolicy: ['expire 500', 'afterUse 2']));
    final dataId3 = await NativeObjectRegister.createObject(NativeObjectCmdData(objectType: NativeObjectType.data, objectTag: tag, releasePolicy: ['keepAlive 200', 'afterUse 4']));
    final dataId4 = await NativeObjectRegister.createObject(NativeObjectCmdData(objectType: NativeObjectType.data, objectTag: tag, releasePolicy: ['keepAlive 200', 'afterUse 4']));
    
    print("Using IDs '$dataId1', '$dataId2', '$dataId3', '$dataId4'");

    // Initial expectation
    await expect(NativeObjectRegister.findObject(dataId1, NativeObjectType.data)).toBe(true);
    await expect(NativeObjectRegister.findObject(dataId2, NativeObjectType.data)).toBe(true);
    await expect(NativeObjectRegister.findObject(dataId3, NativeObjectType.data)).toBe(true);
    await expect(NativeObjectRegister.findObject(dataId4, NativeObjectType.data)).toBe(true);
    await expect((await NativeObjectRegister.countObjects(tag)).valid).toBe(4);

    await sleep(100);
    // After 100ms everything should be still valid
    await expect((await NativeObjectRegister.countObjects(tag)).valid).toBe(4);

    // use dataId4, this will extend its lifetime
    await expect(NativeObjectRegister.useObject(dataId4, NativeObjectType.data)).toBe(true);

    await sleep(100);
    // After next 100ms, dataId3 will be removed
    await expect(NativeObjectRegister.findObject(dataId1, NativeObjectType.data)).toBe(true);
    await expect(NativeObjectRegister.findObject(dataId2, NativeObjectType.data)).toBe(true);
    await expect(NativeObjectRegister.findObject(dataId3, NativeObjectType.data)).toBe(false);
    await expect(NativeObjectRegister.findObject(dataId4, NativeObjectType.data)).toBe(true);

    // Now use dataId2 for 1st time
    await expect(NativeObjectRegister.useObject(dataId2, NativeObjectType.data)).toBe(true);
    
    await expect(NativeObjectRegister.findObject(dataId1, NativeObjectType.data)).toBe(true);
    await expect(NativeObjectRegister.findObject(dataId2, NativeObjectType.data)).toBe(true);
    await expect(NativeObjectRegister.findObject(dataId3, NativeObjectType.data)).toBe(false);
    await expect(NativeObjectRegister.findObject(dataId4, NativeObjectType.data)).toBe(true);

    await sleep(100);
    // Now use dataId2 for 2nd time, it should be released now
    // Also dataId4 is now released
    await expect(NativeObjectRegister.useObject(dataId2, NativeObjectType.data)).toBe(true);
    
    await expect(NativeObjectRegister.findObject(dataId1, NativeObjectType.data)).toBe(true);
    await expect(NativeObjectRegister.findObject(dataId2, NativeObjectType.data)).toBe(false);
    await expect(NativeObjectRegister.findObject(dataId3, NativeObjectType.data)).toBe(false);
    await expect(NativeObjectRegister.findObject(dataId4, NativeObjectType.data)).toBe(false);

    // And finally, use dataId4, to release it

    await expect(NativeObjectRegister.useObject(dataId1, NativeObjectType.data)).toBe(true);

    await expect(NativeObjectRegister.findObject(dataId1, NativeObjectType.data)).toBe(false);
    await expect(NativeObjectRegister.findObject(dataId2, NativeObjectType.data)).toBe(false);
    await expect(NativeObjectRegister.findObject(dataId3, NativeObjectType.data)).toBe(false);
    await expect(NativeObjectRegister.findObject(dataId4, NativeObjectType.data)).toBe(false);
    await expect((await NativeObjectRegister.countObjects(tag)).valid).toBe(0);
  }

  Future<void> testTouchObject() async {

    final dataId1 = await NativeObjectRegister.createObject(NativeObjectCmdData(objectType: NativeObjectType.data, objectTag: tag, releasePolicy: ['keepAlive 100', 'afterUse 4']));
    final dataId2 = await NativeObjectRegister.createObject(NativeObjectCmdData(objectType: NativeObjectType.data, objectTag: tag, releasePolicy: ['keepAlive 100', 'afterUse 4']));
    
    print("Using IDs '$dataId1', '$dataId2'");

    // Initial expectation
    await expect(NativeObjectRegister.findObject(dataId1, NativeObjectType.data)).toBe(true);
    await expect(NativeObjectRegister.findObject(dataId2, NativeObjectType.data)).toBe(true);
    await expect((await NativeObjectRegister.countObjects(tag)).valid).toBe(2);

    await sleep(50);
    // After 50ms everything should be still valid

    // use dataId4, this will extend its lifetime
    await expect(NativeObjectRegister.touchObject(dataId2, NativeObjectType.data)).toBe(true);

    await sleep(50);
    // After next 50ms, dataId3 will be removed
    await expect(NativeObjectRegister.findObject(dataId1, NativeObjectType.data)).toBe(false);
    await expect(NativeObjectRegister.findObject(dataId2, NativeObjectType.data)).toBe(true);
    // Wait for another 50ms to release dataId2
    await sleep(50);
    await expect(NativeObjectRegister.findObject(dataId1, NativeObjectType.data)).toBe(false);
    await expect(NativeObjectRegister.findObject(dataId2, NativeObjectType.data)).toBe(false);
    await expect((await NativeObjectRegister.countObjects(tag)).valid).toBe(0);
  }

  Future<void> testManualRelease() async {

    final dataId1 = await NativeObjectRegister.createObject(NativeObjectCmdData(objectType: NativeObjectType.data, objectTag: tag, releasePolicy: ['afterUse 1', 'manual']));
    final dataId2 = await NativeObjectRegister.createObject(NativeObjectCmdData(objectType: NativeObjectType.data, objectTag: tag, releasePolicy: ['manual', 'expire 100', 'afterUse 2']));
    final dataId3 = await NativeObjectRegister.createObject(NativeObjectCmdData(objectType: NativeObjectType.data, objectTag: tag, releasePolicy: ['keepAlive 100', 'afterUse 4', 'manual']));
    final dataId4 = await NativeObjectRegister.createObject(NativeObjectCmdData(objectType: NativeObjectType.data, objectTag: tag, releasePolicy: ['manual']));

    print("Using IDs '$dataId1', '$dataId2', '$dataId3', '$dataId4'");

    // All manual objects must be in the register for the whole time 
    await expect(NativeObjectRegister.findObject(dataId1, NativeObjectType.data)).toBe(true);
    await expect(NativeObjectRegister.findObject(dataId2, NativeObjectType.data)).toBe(true);
    await expect(NativeObjectRegister.findObject(dataId3, NativeObjectType.data)).toBe(true);
    await expect(NativeObjectRegister.findObject(dataId4, NativeObjectType.data)).toBe(true);
    await expect((await NativeObjectRegister.countObjects(tag)).valid).toBe(4);

    await expect(NativeObjectRegister.useObject(dataId1, NativeObjectType.data)).toBe(true);
    await expect(NativeObjectRegister.findObject(dataId1, NativeObjectType.data)).toBe(true);

    await sleep(110);

    await expect(NativeObjectRegister.findObject(dataId1, NativeObjectType.data)).toBe(true);
    await expect(NativeObjectRegister.findObject(dataId2, NativeObjectType.data)).toBe(true);
    await expect(NativeObjectRegister.findObject(dataId3, NativeObjectType.data)).toBe(true);
    await expect(NativeObjectRegister.findObject(dataId4, NativeObjectType.data)).toBe(true);

    // Now remove objects manually
    await expect(NativeObjectRegister.removeObject(dataId1, NativeObjectType.data)).toBe(true);
    await expect(NativeObjectRegister.removeObject(dataId2, NativeObjectType.data)).toBe(true);
    await expect(NativeObjectRegister.removeObject(dataId3, NativeObjectType.data)).toBe(true);
    await expect(NativeObjectRegister.removeObject(dataId4, NativeObjectType.data)).toBe(true);

    await expect((await NativeObjectRegister.countObjects(tag)).valid).toBe(0);
  }

  Future<void> testAccessWrongObjectType() async {

    final id1 = await NativeObjectRegister.createObject(NativeObjectCmdData(objectType: NativeObjectType.data, objectTag: tag, releasePolicy: ['expire 200']));
    final id2 = await NativeObjectRegister.createObject(NativeObjectCmdData(objectType: NativeObjectType.number, objectTag: tag, releasePolicy: ['expire 200']));

    print("Using IDs '$id1', '$id2''");

    // Correct
    await expect(NativeObjectRegister.findObject(id1, NativeObjectType.data)).toBe(true);
    await expect(NativeObjectRegister.findObject(id2, NativeObjectType.number)).toBe(true);
    // Incorrect type in find
    await expect(NativeObjectRegister.findObject(id1, NativeObjectType.number)).toBe(false);
    await expect(NativeObjectRegister.findObject(id2, NativeObjectType.data)).toBe(false);
    // Incorrect type in use
    await expect(NativeObjectRegister.useObject(id1, NativeObjectType.number)).toBe(false);
    await expect(NativeObjectRegister.useObject(id2, NativeObjectType.data)).toBe(false);
    // Incorrect type in remove
    await expect(NativeObjectRegister.removeObject(id1, NativeObjectType.number)).toBe(false);
    await expect(NativeObjectRegister.removeObject(id2, NativeObjectType.data)).toBe(false);

    // Objects still should be in register
    await expect((await NativeObjectRegister.countObjects(tag)).valid).toBe(2);
    // Correct type in remove
    await expect(NativeObjectRegister.removeObject(id1, NativeObjectType.data)).toBe(true);
    await expect(NativeObjectRegister.removeObject(id2, NativeObjectType.number)).toBe(true);
    
    // After cleanup, count should be 0
    await expect((await NativeObjectRegister.countObjects(tag)).valid).toBe(0);
  }
}