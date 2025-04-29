# Password Change

Since the device does not know the password and is unable to verify the password without the help of the server-side, you need to first call an endpoint that verifies a signature computed with the password.

```dart
// Change password from "oldPassword" to "newPassword".
try {
    await _powerAuth.changePassword(PowerAuthPassword.fromString("oldPassword"), PowerAuthPassword.fromString("newPassword"));
} on PowerAuthException catch (e) {
    print('Change failed: ${e.code}');
} catch (e) {
    print('Unexpected error: $e');
}
```

This method calls `/pa/v3/signature/validate` under the hood with a 2FA signature with the provided original password to verify the password correctness.

## Read Next

- [Working with passwords securely](Secure-Password.md)
