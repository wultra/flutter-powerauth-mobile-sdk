# Biometry Setup

PowerAuth SDK provides an abstraction on top of the base biometry (on Android) and Touch and Face ID (on iOS) support. While the authentication/data signing itself is nicely and transparently embedded in the `PowerAuthAuthentication` object used in [regular request signing](Data-Signing.md), other biometry-related processes require their own API.

## Check Biometry Status

You have to check for biometry on three levels:

- **System Availability**: If a biometric scanner (for example, Touch ID on iOS or Fingerprint reader on Android) is present on the system/device.
- **Activation Availability**: If biometry factor data are available for the given activation.
- **Application Availability**: If the user decides to use biometry for the given app. _(optional)_

PowerAuth SDK provides code for the first two of these checks.

To get the system and activation status, use the following code on a configured `PowerAuth` instance:

```dart
final biometricStatus = await powerAuth.getBiometricStatus();

// Is biometric authentication available for the current activation?
final isAvailable = biometricStatus.isAuthenticationWithBiometricsAvailable;

// Is a biometric factor configured for the current activation?
final isConfigured = biometricStatus.isBiometricFactorConfigured;

// System status and available biometry type.
final systemStatus = biometricStatus.systemStatus;
final biometryType = biometricStatus.biometryType;

// Use this method if you need only the combined availability value.
final canAuthenticate =
    await powerAuth.isAuthenticationWithBiometricsAvailable();

// Use this when only the locally configured factor is relevant.
final hasFactor = await powerAuth.hasBiometryFactor();
```

On Android, the overall availability value does not reflect a temporarily or permanently locked biometric sensor. That state is available only after an authentication attempt. On iOS, `systemStatus` can report `PowerAuthBiometryStatus.lockout`.

On Android, secure facial authentication is available only on devices whose face sensor meets the operating system's strong-biometry requirements. A device can have face recognition for unlocking or convenience features without making it available to PowerAuth.

Your application controls the last check. Store the user's biometry preference in `NSUserDefaults` or `SharedPreferences`. This preference lets the application show that biometry is disabled when the system or activation does not support it.

## Enable Biometry

The device must get the original private key from the Secure Vault before it can create the biometric factor key. Use two-factor authentication with a password to enable biometric authentication.

Use the following code to enable biometric authentication:

```dart
final password = await PowerAuthPassword.fromString("1234");
try {
    // Establish biometric data using provided password
    await powerAuth.addBiometryFactor(
        password,
        PowerAuthBiometricPrompt(
            promptTitle: "Add biometry",
            promptMessage: "Allow biometry factor",
        ),
    );
} catch (e) {
    //failed
}
```

You can omit the prompt on iOS. You can also omit it on Android when `authenticateOnBiometricKeySetup` is `false`.

## Disable Biometry

You can remove biometric-related factor data by simply removing the related key locally, using this one-liner:

```dart
// Remove biometric data
await powerAuth.removeBiometryFactor();
```

After an add or remove operation fails, fetch the activation status to synchronize the local biometric-factor configuration with the server.

## Fetch Biometry Credentials In Advance

You can get reusable biometry credentials when one user interaction must authorize two or more signatures. First, create a `PowerAuthAuthentication` object. Then use it for all required signature calculations. Keep the reusable object only for the required operations. The SDK releases the biometry key after 10 seconds of inactivity. The next use shows the biometric dialog again.

Do not send another request with the same credentials after an HTTP 401 response. Another failed request can block the activation on the server.

In order to obtain biometric credentials for future signature calculations, call the following code:

```dart
// Authenticate user with biometry and obtain PowerAuthAuthentication credentials for future signature calculation.
final auth = PowerAuthAuthentication.biometry(
    biometricPrompt: PowerAuthBiometricPrompt(
        promptTitle: 'Grouped authentication',
        promptMessage: 'One biometric authentication will be used for 2 operations.'
    )
); 
try {
    await powerAuth.groupedBiometricAuthentication(auth, (reusableAuth) async {
        try {
            final r1 = await powerAuth.authenticationHeaderForRequestWithBody(
                reusableAuth,
                "POST",
                "/operation/test",
                Uint8List.fromList(utf8.encode('{"jsonbody":"test1"}')),
            );
            print('r1 success');
            final r2 = await powerAuth.authenticationHeaderForRequestWithBody(
                reusableAuth,
                "POST",
                "/operation/test2",
                Uint8List.fromList(utf8.encode('{"jsonbody":"test2"}')),
            );
            print('r2 success');
            // success
        } catch (e) {
            // reusableAuth usage failed    
        }
    });
} catch (e) {
    // failed to create grouped biometric authentication
}
```

<!-- begin box warning -->
On Android and iOS, a biometric lockout can deliberately produce an invalid biometry factor-related key while reporting successful local key retrieval. The following authenticated request then fails on the server and increases the failed-attempt counter. This limits repeated attempts to deceive the biometric sensor.
<!-- end -->

## Interaction and Concurrency

Allow only one biometric authentication at a time. Do not start parallel biometric prompts or authenticated operations that compete for the same reusable credentials.

On Android, the application can regain focus after the system prompt closes but before the SDK finishes its background cryptographic work. Keep buttons and other interactive controls disabled until the awaited PowerAuth operation completes or throws. Update the UI from that final result, not merely from application focus changes.

The Flutter wrapper does not expose Android `Activity` or `Fragment` prompt objects or iOS `LAContext`.

## Biometry Factor-Related Key Lifetime

By default, the biometry factor-related key is invalidated on Android and is not invalidated on iOS after the user changes the enrolled biometric data. To change this behavior, set `invalidateBiometricFactorAfterChange` [in the advanced configuration](Configuration.md#advanced-configuration).

Be aware that the change in the configuration is effective only for the new keys. So, if your application is already using the biometry factor-related key with a different configuration, then the configuration change doesn't change the existing key. You have to [disable](#disable-biometry) and [enable](#enable-biometry) biometry to apply the change.

## Read Next

- [Device Activation Removal](Device-Activation-Removal.md)
