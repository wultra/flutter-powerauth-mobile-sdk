# Working with passwords securely

The `PowerAuthPassword` class implements safe storage for users' passwords. The class is using an underlying native object to store the user's password securely in memory. The goal is to keep the user's password in memory for as short a time as possible. To achieve this, the native object implements the following precautions: 
 
- If it's constructed with the `destroyOnUse` parameter set to `true`, then the native password is automatically destroyed after it's used for the cryptographic operation.
 
<!-- - If it's constructed with `powerAuthInstanceId`, then the native object will be destroyed after the `PowerAuth` class with the same identifier is deconfigured. -->
 
- If you leave the instance of the `PowerAuthPassword` class as it is, then the native password is removed from memory after 5 minutes of inactivity. The Flutter object is still functional, so if you use any API function, then the native password is re-initialized, but the previous passphrase is lost. 
<!-- You can provide an optional `onAutomaticCleanup` function to the object's constructor to detect this situation. -->
 
- If you call any `PowerAuthPassword` method except `release()`, then the auto-cleanup timer is reset, so the native password will live for another 5 minutes.
 
Be aware that this class is effective only if you're using a numeric PIN for the passphrase, although its API accepts full Unicode code points at the input. This is because it's quite simple to re-implement the PIN keyboard with your custom UI components. On opposite to that, for the full alphanumeric input, you need to use the system keyboard, which already leaves traces of the user's password in memory.

If you're interested in more details about why the passwords should be protected in memory, then you can follow the [Working with passwords securely](https://github.com/wultra/powerauth-mobile-sdk/blob/develop/docs/PowerAuth-SDK-for-iOS.md#working-with-passwords-securely) chapter from the PowerAuth mobile SDK.

## Instantiating password

<!-- 1. Create your own instance: -->
   ```dart
   final password = PowerAuthPassword();
   ```
   Such a password is not bound to any PowerAuth instance, so it will not be destroyed together with the `PowerAuth` instance.

<!-- 2. Create using `PowerAuth` object:
   ```dart
   final password = powerAuth.createPassword();
   ```
   Such a password will be destroyed after the `PowerAuth` instance is deconfigured.

In both ways, you can alter the following parameters:

- `destroyOnUse` is by default `true` and the native password is destroyed automatically after it's used for the cryptographic operation. If you set `false`, then it's recommended to use the `release()` method once the password is no longer needed.

- `onAutomaticCleanup` function is called when the password object detects that the native password was destroyed due to the object's inactivity. See [Automatic cleanup](#automatic-cleanup) chapter for more details. -->

## Using password

```dart
// Creating password from already obtained String
// Note that this is not recommended. Do this only when you retrieve the whole string form a text input.
final password = await PowerAuthPassword.fromString("1234");
```

```dart
// Change password from "0123" to "3210".
try {
    final oldPassword = PowerAuthPassword();
    await oldPassword.addCharacter('0');
    await oldPassword.addCharacter('1');
    await oldPassword.addCharacter('2');
    await oldPassword.addCharacter('3');
    
    final newPassword = PowerAuthPassword();
    await newPassword.addCodePoint(51);
    await newPassword.addCodePoint(50);
    await newPassword.addCodePoint(49);
    await newPassword.addCodePoint(48);
    
    await powerAuth.changePassword(oldPassword, newPassword);
} catch (e) {
    print('Change failed: ${e.code}');
}
```

## Adding or removing characters

```dart
final password = PowerAuthPassword();
var length = await password.length();
print('length = $length');          // length = 0

length = await password.addCharacter('A');
length = await password.addCharacter('B');
print('length = $length');          // length = 2

length = await password.insertCodePoint(48, 2);
length = await password.insertCodePoint(49, 2);
print('length = $length');          // length = 4

length = await password.removeLastCharacter();
length = await password.removeCharacterAt(0);
print('length = $length');          // length = 2

await password.clear();
final empty = await password.isEmpty();
print('empty = $empty');            // empty = true
```

## Compare two passwords

```dart
final p1 = PowerAuthPassword();
final p2 = PowerAuthPassword();
final p3 = PowerAuthPassword();

await p1.addCharacter('0');
await p1.addCharacter('A');

await p2.addCodePoint(48);
await p2.addCodePoint(65);

final p1p2equal = await p1.isEqualTo(p2);
final p2p3equal = await p2.isEqualTo(p3);
print('p1 == p2 is $p1p2equal');    // p1 == p2 is true
print('p2 == p3 is $p2p3equal');    // p2 == p3 is false
```

<!--## Automatic cleanup

The following code explains how the automatic cleanup works:

```dart
// Construct password and setup callback to print the cleanup event to the log.
const password = new PowerAuthPassword(false, () => {
    console.log('Automatic cleanup');
});

let length = await password.addCharacter(48);
console.log(`Length is ${length}`);         // prints 'Length is 1'

// Now release internal native object. Note that the callback is not called.
await password.release();                       

// By calling another API function the native password is restored, but the callback
// is not called, because we released the password manually.
password.addCharacter('💣');
let empty = await password.isEmpty();              
console.log(`empty is ${empty}`);           // prints 'empty is false'

// ... now sleep for 5+ minutes :)

empty = await password.isEmpty();           // prints 'Automatic cleanup'  
console.log(`empty is ${empty}`);           // prints 'empty is true'
```-->

<!--## Testing PIN strength

If password object contains digits only, then you can test the strength of stored PIN:

```javascript
try {
    const result = password.testPinStrength();
    if (result.shouldWarnUserAboutWeakPin) {
        // You should warn user about weak PIN.
        // You can also adjust warning message according to issues found in PIN.
        console.warn(`PIN is weak. Issues = ${JSON.stringify(result.issues)}`);
    }
} catch (e) {
    if (e.code === PowerAuthErrorCode.WRONG_PARAM) {
        // PIN is too short, or passowrd object contains other than digit characters.
    }
}
```

The PIN testing algorithm is based on [Passphrase Meter](https://github.com/wultra/passphrase-meter) library.-->

## Read Next

- [Biometry Setup](Biometry-Setup.md)