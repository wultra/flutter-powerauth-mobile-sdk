# Password Management

## Password Change

Since the device does not know the password and is unable to verify the password without the help of the server-side, you need to first call an endpoint that verifies a signature computed with the password.

```dart
// Change password from "oldPassword" to "newPassword".
try {
    await powerAuth.changePassword(await PowerAuthPassword.fromString("oldPassword"), await PowerAuthPassword.fromString("newPassword"));
} on PowerAuthException catch (e) {
    print('Change failed: ${e.code}');
} catch (e) {
    print('Unexpected error: $e');
}
```

This method calls `/pa/v3/signature/validate` under the hood with a 2FA signature with the provided original password to verify the password correctness.

## Password Validation

You can validate a password by calling the `validatePassword` method.

```dart
// Ask for a password
final password = await PowerAuthPassword.fromString("1234");

// Validate password on the server
try {
    await powerAuth.validatePassword(password);
    // password valid
} catch (e) {
    // password invalid or other error (networking fail, for example)
    return;
}
```

<!-- begin box warning -->
Note that validating user password **should not be done** in situation that precedes the signature calculation, as it's not needed.
If a user enters a wrong PIN should be handled in the calculation call itself and then verified via the `fetchActivationStatus` call.

Example where validation is **not needed**:

1. Call `requestSignature` with a wrong password
2. The call will fail with the `PowerAuthErrorCode.authenticationError` error
3. This means most likely the user entered the wrong password
4. Call `fetchActivationStatus` to verify how many attempts are left or if the activation is blocked.
<!-- end -->

## Read Next

- [Working with passwords securely](Secure-Password.md)
