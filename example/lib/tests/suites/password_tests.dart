import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/suites/test_suite.dart';

class PowerAuthPasswordTests extends TestSuite {

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

    await expect(await p1.isEmpty()).toBe(true, message: "p1 is not empty");
    await expect(await p2.isEmpty()).toBe(true, message: "p2 is not empty");
    await expect(await p1.isEqualTo(pEmpty)).toBe(true, message: "p1 is not equal to pEmpty");
    await expect(await p2.isEqualTo(pEmpty)).toBe(true);
    await expect(await p3.isEqualTo(pEmpty)).toBe(false);

    await expect(await p1.addCharacter('0')).toBe(1);
    await expect(await p2.addCodePoint(48)).toBe(1);
    await expect(await p1.isEqualTo(pEmpty)).toBe(false);
    await expect(await p2.isEqualTo(pEmpty)).toBe(false);
    await expect(await p1.isEmpty()).toBe(false);
    await expect(await p2.isEmpty()).toBe(false);

    await expect(await p1.addCharacter('1')).toBe(2);
    await expect(await p2.addCodePoint(49)).toBe(2);
    await expect(await p1.addCharacter('2')).toBe(3);
    await expect(await p2.addCodePoint(50)).toBe(3);
    await expect(await p1.addCharacter('3')).toBe(4);
    await expect(await p2.addCodePoint(51)).toBe(4);

    await expect(p1.addCodePoint(0x110000)).toThrow(PowerAuthErrorCode.wrongParameter);

    await expect(await p1.isEqualTo(p3)).toBe(true);
    await expect(await p2.isEqualTo(p3)).toBe(true);
    await expect(await p1.isEqualTo(p2)).toBe(true);
    
    p1.clear();
    p2.clear();
    await expect(await p1.isEqualTo(pEmpty)).toBe(true);
    await expect(await p2.isEqualTo(pEmpty)).toBe(true);
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

    await expect(await p1.insertCharacter('l', 0)).toBe(1);
    await expect(await p1.insertCharacter('l', 1)).toBe(2);
    await expect(await p1.insertCharacter('S', 0)).toBe(3);
    await expect(await p1.insertCharacter('k', 1)).toBe(4);
    await expect(await p1.insertCodePoint(0x1F480, 2)).toBe(5);

    await expect(p1.insertCharacter('X', -1)).toThrow(PowerAuthErrorCode.wrongParameter);
    await expect(p1.insertCharacter('X', 6)).toThrow(PowerAuthErrorCode.wrongParameter);
    await expect(p1.insertCodePoint(0x110000, 0)).toThrow(PowerAuthErrorCode.wrongParameter);

    await expect(await p1.isEqualTo(p2)).toBe(true);
  }

  Future<void> testUnicode() async {
    var p1 = await importPassword('★🤣🤫🪘');
    var p2 = await importPassword('Sk💀ll');
    var p3 = PowerAuthPassword();
    var p4 = PowerAuthPassword();
    cleanup.addAll([p1, p2, p3, p4]);
    
    await expect(await p1.length()).toBe(4);
    await expect(await p2.length()).toBe(5);

    await p3.addCharacter('★');
    await p3.addCharacter('🤣🤫');
    await p3.addCharacter('🤫');
    await p3.addCharacter('🪘x');

    await expect(await p3.length()).toBe(4);

    await p4.addCodePoint(0x2605);
    await p4.addCodePoint(0x1F923);
    await p4.addCodePoint(0x1F92B);
    await p4.addCodePoint(0x1FA98);

    await expect(await p4.length()).toBe(4);

    await expect(await p3.isEqualTo(p4)).toBe(true);
    await expect(await p3.isEqualTo(p1)).toBe(true);
    await expect(await p4.isEqualTo(p1)).toBe(true);
  }

  // async testAutomaticCleanup() {
  //     let p1CleanupCalled = 0
  //     let p2CleanupCalled = 0
  //     const p1 = new PowerAuthPassword(false, () => { p1CleanupCalled += 1 }, undefined, 100)
  //     const p2 = new PowerAuthPassword(false, () => { p2CleanupCalled += 1 }, undefined, 100)
  //     this.cleanup.push(p1, p2)

  //     // Right after construct the identifier is not set
  //     const id1AfterCreate = ((p1 as any).objectId)
  //     const id2AfterCreate = ((p2 as any).objectId)
  //     expect(id1AfterCreate).toBeUndefined()
  //     expect(id2AfterCreate).toBeUndefined()
  //     // We have to call at least some function to create underlying native object
  //     expect(await p1.isEmpty()).toBe(true)
  //     expect(await p2.length()).toBe(0)
  //     // Now identifiers are available, but no cleanup was called
  //     const id1AfterAccess = ((p1 as any).objectId)!
  //     const id2AfterAccess = ((p2 as any).objectId)!
  //     expect(id1AfterAccess).toBeDefined()
  //     expect(id2AfterAccess).toBeDefined()
  //     expect(p1CleanupCalled).toBe(0)
  //     expect(p2CleanupCalled).toBe(0)

  //     // Wait for 50ms
  //     await this.sleep(50)
  //     // Both passwords should exist now
  //     expect(await Register.findObject(id1AfterAccess, 'password')).toBe(true)
  //     expect(await Register.findObject(id2AfterAccess, 'password')).toBe(true)
  //     // Access 1st password, to extend it's lifetime
  //     await p1.addCharacter(48)
  //     // Wait for another 50ms, p2 should be released now
  //     await this.sleep(50)

  //     expect(await Register.findObject(id1AfterAccess, 'password')).toBe(true)
  //     expect(await Register.findObject(id2AfterAccess, 'password')).toBe(false)
  //     // native p2 is no longer valid, but its identifier is still set in JS object
  //     expect(((p2 as any).objectId)).toBeDefined()
  //     // Now extend p1 again
  //     expect(await p1.isEmpty()).toBe(false)
  //     // And access p2 again. The callback function should be called now
  //     expect(await p2.isEmpty()).toBe(true)
  //     expect(p2CleanupCalled).toBe(1)

  //     const id2AfterRestore = ((p2 as any).objectId)!
  //     expect(id2AfterRestore).toNotBe(id2AfterAccess)
  //     // Now sleep for another 100ms, so both passwords will be released
  //     await this.sleep(100)
  //     // Touch both objects
  //     expect(await p1.isEqualTo(p2)).toBe(true)
  //     expect(await p1.isEmpty()).toBe(true)
  //     expect(p1CleanupCalled).toBe(1)
  //     expect(p2CleanupCalled).toBe(2)
  //     expect(((p1 as any).objectId)).toNotBe(id1AfterAccess)
  //     expect(((p2 as any).objectId)).toNotBe(id2AfterRestore)
  // }

  // async testReleaseAfterUse() {
  //     let p1CleanupCalled = 0
  //     let p2CleanupCalled = 0
  //     const p1 = new PowerAuthPassword(true, () => { p1CleanupCalled += 1 }, undefined, 100)
  //     const p2 = new PowerAuthPassword(true, () => { p2CleanupCalled += 1 }, undefined, 100)
  //     this.cleanup.push(p1, p2)

  //     await p1.addCharacter(48)
  //     expect(await p1.isEmpty()).toBe(false)
  //     expect(await p2.isEmpty()).toBe(true)
  //     expect(p1CleanupCalled).toBe(0)
  //     expect(p2CleanupCalled).toBe(0)

  //     const id1AfterAccess = ((p1 as any).objectId)!
  //     const id2AfterAccess = ((p2 as any).objectId)!

  //     expect(await Register.useObject(id1AfterAccess, 'password')).toBe(true)
  //     expect(await Register.useObject(id2AfterAccess, 'password')).toBe(true)

  //     expect(await p1.isEmpty()).toBe(true)
  //     expect(await p2.isEmpty()).toBe(true)

  //     expect(p1CleanupCalled).toBe(1)
  //     expect(p2CleanupCalled).toBe(1)

  //     expect(await Register.findObject(id1AfterAccess, 'password')).toBe(false)
  //     expect(await Register.findObject(id2AfterAccess, 'password')).toBe(false)
  // }
  
  Future<void> testManualRelease() async {
    // var p1CleanupCalled = 0;
    // var p2CleanupCalled = 0;
    // const p1 = PowerAuthPassword(false, () => { p1CleanupCalled += 1 }, undefined, 100)
    // const p2 = PowerAuthPassword(true, () => { p2CleanupCalled += 1 }, undefined, 100)
    var p1 = PowerAuthPassword(destroyOnUse: false, powerAuthInstanceId: null, autoReleaseTimeMillis: 100);
    var p2 = PowerAuthPassword(destroyOnUse: true, powerAuthInstanceId: null, autoReleaseTimeMillis: 100);
    cleanup.addAll([p1, p2]);

    // Native objects are no created yet
    await p1.release();
    await p2.release();

    // expect(p1CleanupCalled).toBe(0)
    // expect(p2CleanupCalled).toBe(0)

    await p1.addCodePoint(48);
    await expect(await p1.isEmpty()).toBe(false);
    await expect(await p2.isEmpty()).toBe(true);

    var id1AfterAccess = p1.objectId;
    var id2AfterAccess = p2.objectId;
    await expect(id1AfterAccess).toBeDefined();
    await expect(id2AfterAccess).toBeDefined();

    // expect(p1CleanupCalled).toBe(0);
    // expect(p2CleanupCalled).toBe(0);

    // Now manually release passwords
    await p1.release();
    await p2.release();

    // Both passwords should be released and throw on access
    await expect(p1.addCharacter('1')).toThrow(PowerAuthErrorCode.invalidNativeObject);
    await expect(p2.addCharacter('1')).toThrow(PowerAuthErrorCode.invalidNativeObject);

    // expect(await Register.findObject(id1AfterAccess, 'password')).toBe(false)
    // expect(await Register.findObject(id2AfterAccess, 'password')).toBe(false)

    // expect(p1CleanupCalled).toBe(0);
    // expect(p2CleanupCalled).toBe(0);

    // Instantiate again, this should not call onAutomaticCleanup, because 
    // release was initiated by application
    // await p1.addCodePoint(48);
    // expect(await p1.isEmpty()).toBe(false);
    // expect(await p2.isEmpty()).toBe(true);
    // expect(p1CleanupCalled).toBe(0)
    // expect(p2CleanupCalled).toBe(0)

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
  //     const config = new PowerAuthConfiguration('6NgAwrP3iLfbuN2S8vCyEw==', '6N6JAkZhTTmeDoJG0llXhA==', 'BCgc7k0uu5wjYdbRxObMCLr7vDD5JQW//C0kRZSUYlyixAj/fllAx3pbkHZhogTL42EBUbKZeVqtXsw2PE46SJs=', 'http://localhost/wrong')

  //     // Owner object represents an instance of PowerAuth class that typically owns various object types
  //     const powerAuthInstanceId = this.getRandomId()
  //     const powerAuth = new PowerAuth(powerAuthInstanceId)
  //     this.cleanup.push(powerAuth)

  //     // We can create passwords even in PA instance is not configured, but every call to password API will fail
  //     let p1CleanupCalled = 0
  //     let p2CleanupCalled = 0
  //     const p1 = powerAuth.createPassword(false, () => p2CleanupCalled += 1)
  //     const p2 = powerAuth.createPassword(true, () => p2CleanupCalled += 1)
  //     this.cleanup.push(p1, p2)
  //     expect((p1 as any).powerAuthInstanceId).toBe(powerAuthInstanceId)
  //     expect((p2 as any).powerAuthInstanceId).toBe(powerAuthInstanceId)

  //     // PA instance is not configured yet, so the underlying password cannot be created.
  //     await expect(async () => p1.addCharacter(48)).toThrow({errorCode: PowerAuthErrorCode.INSTANCE_NOT_CONFIGURED })
  //     await expect(async () => p2.removeLastCharacter()).toThrow({errorCode: PowerAuthErrorCode.INSTANCE_NOT_CONFIGURED })

  //     // Configure PA instance
  //     await powerAuth.configure(config)

  //     // Now everything should work as expected
  //     await p1.addCharacter(48)
  //     expect(await p1.isEmpty()).toBe(false)
  //     expect(await p2.isEmpty()).toBe(true)
  //     expect(p1CleanupCalled).toBe(0)
  //     expect(p2CleanupCalled).toBe(0)

  //     const id1AfterAccess = ((p1 as any).objectId)!
  //     const id2AfterAccess = ((p2 as any).objectId)!
      
  //     expect(await Register.findObject(id1AfterAccess, 'password')).toBe(true)
  //     expect(await Register.findObject(id2AfterAccess, 'password')).toBe(true)

  //     // Now deconfigure PA instance
  //     await powerAuth.deconfigure()
  //     // Both passwords should be released
  //     expect(await Register.findObject(id1AfterAccess, 'password')).toBe(false)
  //     expect(await Register.findObject(id2AfterAccess, 'password')).toBe(false)

  //     // Now any access to password leads to the error, because parent object is not in the register
  //     await expect(async () => p1.isEmpty()).toThrow({errorCode: PowerAuthErrorCode.INSTANCE_NOT_CONFIGURED })
  //     await expect(async () => p2.length()).toThrow({errorCode: PowerAuthErrorCode.INSTANCE_NOT_CONFIGURED })

  //     // Configure PA instance again
  //     await powerAuth.configure(config)

  //     expect(await p1.isEmpty()).toBe(true)
  //     expect(await p2.isEmpty()).toBe(true)
  // }

  Future<PowerAuthPassword> importPassword(String password) {
    return PowerAuthPassword.fromString(password);
  }
}