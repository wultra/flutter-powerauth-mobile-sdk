# Working with passwords securely

The `PowerAuthPassword` class stores a user's password in a native object. This design keeps the password out of Dart memory after construction. The native object applies these rules:
 
- The SDK creates the native object when you first use the password.
- If `destroyOnUse` is `true`, the SDK destroys the native password after the first cryptographic operation. This is the default setting.
- The SDK destroys the native password after 5 minutes of inactivity.
- A method call resets the inactivity timer.
- If `powerAuthInstanceId` is set, deconfiguration of that `PowerAuth` instance destroys the password.
- A call to `release()` destroys the password immediately.

After the SDK destroys or releases the native password, another use reports `PowerAuthErrorCode.invalidNativeObject`. Create a new `PowerAuthPassword` object when you need the password again.
 
This class gives the best protection for a numeric PIN. You can implement a custom PIN keyboard without a complete Dart string. The API also accepts Unicode code points. An alphanumeric password usually requires the system keyboard, which can leave password data in memory.

For more information, see [Working with passwords securely](https://github.com/wultra/powerauth-mobile-sdk/blob/develop/docs/PowerAuth-SDK-for-iOS.md#working-with-passwords-securely) in the native SDK documentation.

## Instantiating password

```dart
final password = PowerAuthPassword();
```

This password is not bound to a `PowerAuth` instance. To bind its lifetime to an instance, set `powerAuthInstanceId`:

```dart
final password = PowerAuthPassword(
    powerAuthInstanceId: powerAuth.instanceId,
);
```

## Using password

```dart
// Creating password from already obtained String
// This is not recommended. Use it only when you retrieve the whole string from a text input.
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
    
    final changeData = await powerAuth.beginPasswordChange(oldPassword);
    try {
        await powerAuth.finishPasswordChange(newPassword, changeData);
    } finally {
        await changeData.release();
    }
} on PowerAuthException catch (e) {
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

## Read Next

- [Biometry Setup](Biometry-Setup.md)
