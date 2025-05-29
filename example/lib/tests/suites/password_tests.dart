import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/suites/test_suite.dart';

class PasswordTests extends TestSuite {

  @override 
  getTests() {
    return [testAddCharacters, testRemoveCharacters, testInsertCharacters, testUnicode, testManualRelease];
  }

  Future<void> testAddCharacters() async {
    var p1 = PowerAuthPassword();
    var p2 = PowerAuthPassword();
    var p3 = await PowerAuthPassword.fromString('0123');
    var pEmpty = PowerAuthPassword();
    cleanup.addAll([p1, p2, p3, pEmpty]);

    await expect(p1.isEmpty()).toBe(true, message: "p1 is not empty");
    await expect(p2.isEmpty()).toBe(true, message: "p2 is not empty");
    await expect(p1.isEqualTo(pEmpty)).toBe(true, message: "p1 is not equal to pEmpty");
    await expect(p2.isEqualTo(pEmpty)).toBe(true);
    await expect(p3.isEqualTo(pEmpty)).toBe(false);

    await expect(p1.addCharacter('0')).toBe(1);
    await expect(p2.addCodePoint(48)).toBe(1);
    await expect(p1.isEqualTo(pEmpty)).toBe(false);
    await expect(p2.isEqualTo(pEmpty)).toBe(false);
    await expect(p1.isEmpty()).toBe(false);
    await expect(p2.isEmpty()).toBe(false);

    await expect(p1.addCharacter('1')).toBe(2);
    await expect(p2.addCodePoint(49)).toBe(2);
    await expect(p1.addCharacter('2')).toBe(3);
    await expect(p2.addCodePoint(50)).toBe(3);
    await expect(p1.addCharacter('3')).toBe(4);
    await expect(p2.addCodePoint(51)).toBe(4);

    await expect(p1.addCodePoint(0x110000)).toThrow(PowerAuthErrorCode.wrongParameter);

    await expect(p1.isEqualTo(p3)).toBe(true);
    await expect(p2.isEqualTo(p3)).toBe(true);
    await expect(p1.isEqualTo(p2)).toBe(true);
    
    p1.clear();
    p2.clear();
    await expect(p1.isEqualTo(pEmpty)).toBe(true);
    await expect(p2.isEqualTo(pEmpty)).toBe(true);
  }

  Future<void> testRemoveCharacters() async {
    var p1 = await importPassword('Sk💀Ll');
    var t1 = await importPassword('k💀Ll');
    var t2 = await importPassword('k💀L');
    var t3 = await importPassword('kL');
    var t4 = await importPassword('k');
    cleanup.addAll([p1, t1, t2, t3, t4]);

    await expect(p1.removeCharacterAt(-1)).toThrow(PowerAuthErrorCode.wrongParameter, message: "negative index");
    await expect(p1.removeCharacterAt(5)).toThrow(PowerAuthErrorCode.wrongParameter, message: "index out of range");

    await expect(p1.removeCharacterAt(0)).toBe(4);
    await expect(p1.isEqualTo(t1)).toBe(true);
    await expect(p1.removeLastCharacter()).toBe(3);
    await expect(p1.isEqualTo(t2)).toBe(true);
    await expect(p1.removeCharacterAt(1)).toBe(2);
    await expect(p1.isEqualTo(t3)).toBe(true);
    await expect(p1.removeCharacterAt(1)).toBe(1);
    await expect(p1.isEqualTo(t4)).toBe(true);
    await expect(p1.removeCharacterAt(0)).toBe(0);
    await expect(p1.length()).toBe(0);
    // Pop last should not fail
    await expect(p1.removeLastCharacter()).toBe(0);

    await expect(p1.removeCharacterAt(0)).toThrow(PowerAuthErrorCode.wrongParameter, message: "index out of range");
}

Future<void> testInsertCharacters() async {
    var p1 = PowerAuthPassword();
    var p2 = await importPassword('Sk💀ll');
    cleanup.addAll([p1, p2]);

    await expect(p1.insertCharacter('l', 0)).toBe(1);
    await expect(p1.insertCharacter('l', 1)).toBe(2);
    await expect(p1.insertCharacter('S', 0)).toBe(3);
    await expect(p1.insertCharacter('k', 1)).toBe(4);
    await expect(p1.insertCodePoint(0x1F480, 2)).toBe(5);

    await expect(p1.insertCharacter('X', -1)).toThrow(PowerAuthErrorCode.wrongParameter);
    await expect(p1.insertCharacter('X', 6)).toThrow(PowerAuthErrorCode.wrongParameter);
    await expect(p1.insertCodePoint(0x110000, 0)).toThrow(PowerAuthErrorCode.wrongParameter);

    await expect(p1.isEqualTo(p2)).toBe(true);
  }

  Future<void> testUnicode() async {
    var p1 = await importPassword('★🤣🤫🪘');
    var p2 = await importPassword('Sk💀ll');
    var p3 = PowerAuthPassword();
    var p4 = PowerAuthPassword();
    cleanup.addAll([p1, p2, p3, p4]);
    
    await expect(p1.length()).toBe(4);
    await expect(p2.length()).toBe(5);

    await p3.addCharacter('★');
    await p3.addCharacter('🤣🤫');
    await p3.addCharacter('🤫');
    await p3.addCharacter('🪘x');

    await expect(p3.length()).toBe(4);

    await p4.addCodePoint(0x2605);
    await p4.addCodePoint(0x1F923);
    await p4.addCodePoint(0x1F92B);
    await p4.addCodePoint(0x1FA98);

    await expect(p4.length()).toBe(4);

    await expect(p3.isEqualTo(p4)).toBe(true);
    await expect(p3.isEqualTo(p1)).toBe(true);
    await expect(p4.isEqualTo(p1)).toBe(true);
  }

  Future<void> testAutomaticCleanup() async {

    final p1 = PowerAuthPassword(destroyOnUse: false, powerAuthInstanceId: null, autoReleaseTimeMillis: 100);
    final p2 = PowerAuthPassword(destroyOnUse: false, powerAuthInstanceId: null, autoReleaseTimeMillis: 100);
    cleanup.addAll([p1, p2]);

    // Right after construct the identifier is not set
    final id1AfterCreate = p1.objectId;
    final id2AfterCreate = p2.objectId;
    await expect(id1AfterCreate).toBeNull();
    await expect(id2AfterCreate).toBeNull();
    // We have to call at least some function to create underlying native object
    await expect(p1.isEmpty()).toBe(true, message: "1");
    await expect(p2.length()).toBe(0);
    // Now identifiers are available, but no cleanup was called
    final id1AfterAccess = p1.objectId!;
    final id2AfterAccess = p2.objectId!;
    await expect(id1AfterAccess).toBeDefined();
    await expect(id2AfterAccess).toBeDefined();

    // Wait for 50ms
    await sleep(50);
    // Both passwords should exist now
    await expect(NativeObjectRegister.findObject(id1AfterAccess, NativeObjectType.password)).toBe(true, message: "2");
    await expect(NativeObjectRegister.findObject(id2AfterAccess, NativeObjectType.password)).toBe(true, message: "3");
    // Access 1st password, to extend it's lifetime
    await p1.addCodePoint(48);
    // Wait for another 50ms, p2 should be released now
    await sleep(50);

    await expect(NativeObjectRegister.findObject(id1AfterAccess, NativeObjectType.password)).toBe(true, message: "4");
    await expect(NativeObjectRegister.findObject(id2AfterAccess, NativeObjectType.password)).toBe(false);
    // native p2 is no longer valid, but its identifier is still set in JS object
    await expect(p2.objectId).toBeDefined();
    // Now extend p1 again
    await expect(p1.isEmpty()).toBe(false);
    // And access p2 again. Invalid native object should be thrown
    await expect(p2.isEmpty()).toThrow(PowerAuthErrorCode.invalidNativeObject);
    
    // Now sleep for another 100ms, so both passwords will be released
    await sleep(100);

    await expect(p1.isEmpty()).toThrow(PowerAuthErrorCode.invalidNativeObject);
  }

  Future<void> testReleaseAfterUse() async {

    final p1 = PowerAuthPassword(destroyOnUse: true, powerAuthInstanceId: null, autoReleaseTimeMillis: 100);
    final p2 = PowerAuthPassword(destroyOnUse: true, powerAuthInstanceId: null, autoReleaseTimeMillis: 100);
    cleanup.addAll([p1, p2]);

    await p1.addCodePoint(48);
    await expect(p1.isEmpty()).toBe(false);
    await expect(p2.isEmpty()).toBe(true);

    final id1AfterAccess = p1.objectId!;
    final id2AfterAccess = p2.objectId!;

    await expect(NativeObjectRegister.useObject(id1AfterAccess, NativeObjectType.password)).toBe(true);
    await expect(NativeObjectRegister.useObject(id2AfterAccess, NativeObjectType.password)).toBe(true);

    // Both object should be invalid when used once
    await expect(p1.isEmpty()).toThrow(PowerAuthErrorCode.invalidNativeObject);
    await expect(p2.isEmpty()).toThrow(PowerAuthErrorCode.invalidNativeObject);

    await expect(NativeObjectRegister.findObject(id1AfterAccess, NativeObjectType.password)).toBe(false);
    await expect(NativeObjectRegister.findObject(id2AfterAccess, NativeObjectType.password)).toBe(false);
  }
  
  Future<void> testManualRelease() async {
    // var p1CleanupCalled = 0;
    // var p2CleanupCalled = 0;
    // final p1 = PowerAuthPassword(false, () => { p1CleanupCalled += 1 }, undefined, 100)
    // final p2 = PowerAuthPassword(true, () => { p2CleanupCalled += 1 }, undefined, 100)
    var p1 = PowerAuthPassword(destroyOnUse: false, powerAuthInstanceId: null, autoReleaseTimeMillis: 100);
    var p2 = PowerAuthPassword(destroyOnUse: true, powerAuthInstanceId: null, autoReleaseTimeMillis: 100);
    cleanup.addAll([p1, p2]);

    // Native objects are no created yet
    await p1.release();
    await p2.release();

    // await expect(p1CleanupCalled).toBe(0)
    // await expect(p2CleanupCalled).toBe(0)

    await p1.addCodePoint(48);
    await expect(p1.isEmpty()).toBe(false);
    await expect(p2.isEmpty()).toBe(true);

    var id1AfterAccess = p1.objectId;
    var id2AfterAccess = p2.objectId;
    await expect(id1AfterAccess).toBeDefined();
    await expect(id2AfterAccess).toBeDefined();

    // await expect(p1CleanupCalled).toBe(0);
    // await expect(p2CleanupCalled).toBe(0);

    // Now manually release passwords
    await p1.release();
    await p2.release();

    // Both passwords should be released and throw on access
    await expect(p1.addCharacter('1')).toThrow(PowerAuthErrorCode.invalidNativeObject);
    await expect(p2.addCharacter('1')).toThrow(PowerAuthErrorCode.invalidNativeObject);

    // await expect(Register.findObject(id1AfterAccess, 'password')).toBe(false)
    // await expect(Register.findObject(id2AfterAccess, 'password')).toBe(false)

    // await expect(p1CleanupCalled).toBe(0);
    // await expect(p2CleanupCalled).toBe(0);

    // Instantiate again, this should not call onAutomaticCleanup, because 
    // release was initiated by application
    // await p1.addCodePoint(48);
    // await expect(p1.isEmpty()).toBe(false);
    // await expect(p2.isEmpty()).toBe(true);
    // await expect(p1CleanupCalled).toBe(0)
    // await expect(p2CleanupCalled).toBe(0)

    // Now release for multiple times, to make sure that function doesn't fail
    await p1.release();
    await p2.release();
    await p1.release();
    await p2.release();
  }

  // getRandomId(): string {
  //     return 'instanceId_' + (Math.random() + 1).toString(36).substring(7)
  // }

  // async testGlobalRelease() {
  //     // Dummy values for PA configuration
  //     final config = new PowerAuthConfiguration('6NgAwrP3iLfbuN2S8vCyEw==', '6N6JAkZhTTmeDoJG0llXhA==', 'BCgc7k0uu5wjYdbRxObMCLr7vDD5JQW//C0kRZSUYlyixAj/fllAx3pbkHZhogTL42EBUbKZeVqtXsw2PE46SJs=', 'http://localhost/wrong')

  //     // Owner object represents an instance of PowerAuth class that typically owns various object types
  //     final powerAuthInstanceId = this.getRandomId()
  //     final powerAuth = new PowerAuth(powerAuthInstanceId)
  //     this.cleanup.push(powerAuth)

  //     // We can create passwords even in PA instance is not configured, but every call to password API will fail
  //     let p1CleanupCalled = 0
  //     let p2CleanupCalled = 0
  //     final p1 = powerAuth.createPassword(false, () => p2CleanupCalled += 1)
  //     final p2 = powerAuth.createPassword(true, () => p2CleanupCalled += 1)
  //     this.cleanup.push(p1, p2)
  //     await expect((p1 as any).powerAuthInstanceId).toBe(powerAuthInstanceId)
  //     await expect((p2 as any).powerAuthInstanceId).toBe(powerAuthInstanceId)

  //     // PA instance is not configured yet, so the underlying password cannot be created.
  //     await expect(async () => p1.addCharacter(48)).toThrow({errorCode: PowerAuthErrorCode.INSTANCE_NOT_CONFIGURED })
  //     await expect(async () => p2.removeLastCharacter()).toThrow({errorCode: PowerAuthErrorCode.INSTANCE_NOT_CONFIGURED })

  //     // Configure PA instance
  //     await powerAuth.configure(config)

  //     // Now everything should work as expected
  //     await p1.addCharacter(48)
  //     await expect(p1.isEmpty()).toBe(false)
  //     await expect(p2.isEmpty()).toBe(true)
  //     await expect(p1CleanupCalled).toBe(0)
  //     await expect(p2CleanupCalled).toBe(0)

  //     final id1AfterAccess = ((p1 as any).objectId)!
  //     final id2AfterAccess = ((p2 as any).objectId)!
      
  //     await expect(Register.findObject(id1AfterAccess, 'password')).toBe(true)
  //     await expect(Register.findObject(id2AfterAccess, 'password')).toBe(true)

  //     // Now deconfigure PA instance
  //     await powerAuth.deconfigure()
  //     // Both passwords should be released
  //     await expect(Register.findObject(id1AfterAccess, 'password')).toBe(false)
  //     await expect(Register.findObject(id2AfterAccess, 'password')).toBe(false)

  //     // Now any access to password leads to the error, because parent object is not in the register
  //     await expect(async () => p1.isEmpty()).toThrow({errorCode: PowerAuthErrorCode.INSTANCE_NOT_CONFIGURED })
  //     await expect(async () => p2.length()).toThrow({errorCode: PowerAuthErrorCode.INSTANCE_NOT_CONFIGURED })

  //     // Configure PA instance again
  //     await powerAuth.configure(config)

  //     await expect(p1.isEmpty()).toBe(true)
  //     await expect(p2.isEmpty()).toBe(true)
  // }

  Future<PowerAuthPassword> importPassword(String password) {
    return PowerAuthPassword.fromString(password);
  }
}