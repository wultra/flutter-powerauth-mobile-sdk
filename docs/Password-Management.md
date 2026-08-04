# Password Management

## Password Change

The device cannot validate a password without help from PowerAuth Server. Use the two-step password change API. The first step validates the old password and returns native-backed change data. The second step sets the new password.

```dart
final oldPassword = await PowerAuthPassword.fromString("oldPassword");
final newPassword = await PowerAuthPassword.fromString("newPassword");
final changeData = await powerAuth.beginPasswordChange(oldPassword);

try {
    await powerAuth.finishPasswordChange(newPassword, changeData);
} on PowerAuthException catch (e) {
    print('Change failed: ${e.code}');
} finally {
    // finishPasswordChange() releases the object automatically.
    // Repeated calls to release() are safe. This call also covers an abandoned operation.
    await changeData.release();
}
```

`finishPasswordChange()` consumes and releases `PowerAuthPasswordChangeData` after success or failure. Call `release()` if the user stops the operation before the second step.

## Password Validation

Version 2.0 removes `validatePassword()` and does not provide a direct replacement. A separate password validation step can create a security problem. Run the operation that requires the password and handle its result.

<!-- begin box warning -->
Do not validate a password before a signature calculation. If an authenticated operation fails, call `fetchActivationStatus()` to get the remaining attempts and the activation state.
<!-- end -->

## Read Next

- [Working with passwords securely](Secure-Password.md)
