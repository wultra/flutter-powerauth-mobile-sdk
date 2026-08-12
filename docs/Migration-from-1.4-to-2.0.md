# Migration from 1.4.x to 2.0.x

PowerAuth Mobile Flutter SDK version `2.0.0` uses PowerAuth Mobile SDK version `2.0.0` on Android and iOS. This version contains the following changes:

- PowerAuth protocol version 4.0 adds P-384 algorithms and optional post-quantum protection with ML-KEM and ML-DSA.
- Existing activations can use an authenticated protocol upgrade to move from protocol 3.3 to protocol 4.0.
- The SDK can stay in legacy protocol 3.3 mode during a staged server migration.
- The SDK uses native objects to keep more sensitive data out of Dart memory.
- Request signing, digital signatures, end-to-end encryption, biometry, password changes, and Secure Vault operations use new APIs.
- The minimum supported Android version is now Android 6.0 (API 23).

### Compatibility with PowerAuth Server

- Protocol 4.0 requires PowerAuth Server version `2.0.0` or later.
- Legacy protocol 3.3 requires PowerAuth Server version `1.9.0` or later.

### Platform Requirements

- Flutter `3.44.0` or later and Dart `3.12.0` or later.
- Android 6.0 (API 23) or later with Java 17 compatibility enabled.
- iOS 13.4 or later.

## Configuration

The default algorithm is `PowerAuthAlgorithm.p384l3`. It requires PowerAuth Server `2.0.0` or later. Set `algorithm` to `PowerAuthAlgorithm.legacy` if the application must stay on protocol 3.3 during migration.

```dart
final configuration = PowerAuthConfiguration(
    configuration: "ARCB+/qxp........IQ5E5jg==",
    baseEndpointUrl: "https://<your-domain>/enrollment-server",
    algorithm: PowerAuthAlgorithm.legacy,
);
```

The supported algorithms are:

- `legacy` uses P-256 and protocol 3.3. Use it only for a staged migration and switch to at least `p384` after PowerAuth Server is upgraded to version 2.0.
- `p384` uses P-384 without post-quantum protection. Use it only when the infrastructure cannot handle the load of post-quantum algorithms.
- `p384l3` uses P-384, ML-KEM-768, and ML-DSA-65. This is the default algorithm and the recommended balance of security and performance.
- `p384l5` uses P-384, ML-KEM-1024, and ML-DSA-87 and provides the highest security level.

`PowerAuthConfiguration` also contains `offlineAuthenticationCodeComponentLength`. The permitted values are from `4` through `8`. The default value is `8`.

The selected algorithm cannot be changed on an already configured `PowerAuth` instance. It can change in a later application version, but an activation created with a different algorithm must complete an authenticated protocol upgrade.

The configuration properties are asynchronous. Use `await` to read them:

```dart
final configuration = await powerAuth.configuration;
final algorithm = await powerAuth.currentAlgorithm;
final clientConfiguration = await powerAuth.clientConfiguration;
final biometryConfiguration = await powerAuth.biometryConfiguration;
final keychainConfiguration = await powerAuth.keychainConfiguration;
final sharingConfiguration = await powerAuth.sharingConfiguration;
```

The client configuration does not return `customHttpHeaders` or `basicHttpAuthentication`. Keep the original `PowerAuthClientConfiguration` if you must use these values again.

`PowerAuthKeychainConfiguration` is now Android-specific. Configure iOS activation sharing only with `PowerAuthSharingConfiguration`. The following properties were removed from `PowerAuthKeychainConfiguration`:

- `PowerAuthKeychainConfiguration.accessGroupName`
- `PowerAuthKeychainConfiguration.userDefaultsSuiteName`

`PowerAuthSharingConfiguration.sharedMemoryIdentifier` remains available as an optional iOS setting. If omitted everywhere, the native SDK derives the shared-memory identifier from the shared `PowerAuth` instance identifier. When set explicitly, use the same value in all participating applications and extensions. The value must contain 1 to 4 UTF-8 bytes and may contain only ASCII letters, digits, `+`, and `-`.

After configuration, the asynchronous `sharingConfiguration` getter returns the effective native value, including a generated `sharedMemoryIdentifier` when the input omitted it.

If configuration fails with `PowerAuthErrorCode.invalidActivationData`, call `cleanupInstanceData()` with the same configuration values. Then configure the instance again. If configuration fails with `PowerAuthErrorCode.upgradeSdk`, update the application to a newer SDK. Do not delete the activation data.

## Activation Data Sharing

PowerAuth Mobile SDK 2.0 uses a new activation data format. This format can cause a problem if multiple applications share one activation and are updated at different times.

Use this procedure for applications that share activation data:

1. Update all applications to SDK 2.0 and set `PowerAuthAlgorithm.legacy`.
2. Wait until a sufficient number of users install the new versions of all applications.
3. Change the algorithm to the selected protocol 4.0 algorithm.

You do not need this procedure if only one application and its extensions share activation data. The application and its extensions are updated together.

See [Share Activation Data](Activation-Data-Sharing.md) for the complete target, entitlement, and runtime configuration.

## Authenticated Protocol Upgrade

An activation that uses protocol 3.3 must complete an authenticated protocol upgrade before it can use a protocol 4.0 algorithm.

```dart
await powerAuth.fetchActivationStatus();
if (await powerAuth.hasProtocolUpgradeAvailable()) {
    final password = await PowerAuthPassword.fromString("1234");
    final result = await powerAuth.startProtocolUpgrade(password);
    if (result.activationStatusFetchRequired) {
        await powerAuth.fetchActivationStatus();
    }
}
```

On iOS, the SDK preserves an existing biometry factor automatically. On Android, set `upgradeBiometry` to `true` to migrate an existing biometry factor. This option works only when `authenticateOnBiometricKeySetup` is `false`. If `result.biometryFactorRemoved` is `true`, add the biometry factor again after the upgrade.

## Password Change

The `changePassword()` and `validatePassword()` methods were removed. Password validation has no direct replacement. Do not validate a password before another authenticated operation. Handle an authentication failure from that operation and then fetch the activation status.

Use the two-step API to change a password:

```dart
final oldPassword = await PowerAuthPassword.fromString("1234");
final newPassword = await PowerAuthPassword.fromString("5678");
final changeData = await powerAuth.beginPasswordChange(oldPassword);

try {
    await powerAuth.finishPasswordChange(newPassword, changeData);
} catch (_) {
    // finishPasswordChange() releases changeData after success or failure.
    rethrow;
}
```

Call `changeData.release()` if the user stops the operation before `finishPasswordChange()` starts.

## Request Authentication

The request-signature methods and header type changed:

| Removed API | Replacement |
|---|---|
| `requestGetSignature()` | `authenticationHeaderForRequestWithParams()` |
| `requestSignature()` | `authenticationHeaderForRequestWithBody()` |
| `PowerAuthAuthorizationHttpHeader` | `PowerAuthHttpHeader` |

`PowerAuthHttpHeader.name` replaces `PowerAuthAuthorizationHttpHeader.key`. `PowerAuthTokenStore.generateHeaderForToken()` now also returns `PowerAuthHttpHeader`.

The method with query parameters now requires the HTTP method. The method with a request body now accepts `Uint8List`.

```dart
final header = await powerAuth.authenticationHeaderForRequestWithBody(
    authentication,
    "POST",
    "/payment/create",
    Uint8List.fromList(utf8.encode(jsonEncode(requestBody))),
);
```

`offlineSignature()` also accepts the request body as `Uint8List`.

The native SDK now validates the purpose of every `PowerAuthAuthentication` object. Use `possession()`, `password()`, or `biometry()` for authenticated operations. Use `persistWithPassword()` or `persistWithPasswordAndBiometry()` only for `persistActivation()`. Mixing the two purposes reports an error.

## Digital Signatures, JWS, and Certificates

The digital-signature API now uses raw bytes and an explicit `PowerAuthSignatureKeyId`:

| Removed API | Replacement |
|---|---|
| `signDataWithDevicePrivateKey()` | `calculateDigitalSignature()` |
| `verifyServerSignedData()` | `verifyDigitalSignature()` |

`calculateDigitalSignature()` returns `Uint8List`. `verifyDigitalSignature()` completes without a value when the signature is valid. It throws `PowerAuthErrorCode.wrongSignature` when the signature is not valid.

Version 2.0 also adds these methods:

- `calculateJwsSignature()`
- `verifyJwsSignature()`
- `createCertificateSigningRequest()`
- `exportDevicePublicKeys()`

The available signature keys depend on the configured algorithm. EC keys are always available. ML-DSA keys are available only with `p384l3` and `p384l5`. Use a key with a specific type, such as `deviceEc`, for a non-JWS digital signature. Hybrid key identifiers are supported only by the JWS API.

A compact JWT contains one signature. Use an exact key type, such as `deviceEc`, `deviceMlDsa`, `serverEc`, or `serverMlDsa`, when creating or verifying the compact form. Generic identifiers such as `device` and `server` can select two keys with a hybrid algorithm and belong with non-compact JWS.

Prefix every certificate subject alternative name with its type, for example `IP: 192.168.1.10`, `DNS: example.com`, or `email: admin@example.com`.

## Activation Code QR Signatures

SDK versions older than 2.0 allowed applications to verify the signature suffix in an activation code scanned from a QR code. SDK 2.0 no longer supports this verification because post-quantum signatures are too large to embed in the QR code. If the scanned value contains a legacy suffix, use `PowerAuthActivationCodeUtil.parseActivationCode()` to validate the code and strip the suffix. The activation process ignores the suffix; do not treat it as proof that the code is trusted.

## Biometric Authentication

The static `PowerAuth.getBiometryInfo()` method and `PowerAuthBiometryInfo` class were removed. Use the configured `PowerAuth` instance:

```dart
final status = await powerAuth.getBiometricStatus();
final isAvailable = status.isAuthenticationWithBiometricsAvailable;
final isConfigured = status.isBiometricFactorConfigured;
final systemStatus = status.systemStatus;
final biometryType = status.biometryType;
```

You can use `isAuthenticationWithBiometricsAvailable()` when you only need the combined availability value.

`PowerAuthBiometryConfiguration.linkItemsToCurrentSet` was renamed to `invalidateBiometricFactorAfterChange`. On Android, new biometric factors use HMAC-KDF protection by default. Existing biometric factors continue to work. Enable `useLegacySymmetricKey` only when newly configured biometric factors must remain compatible with the legacy AES-KDF protection from PowerAuth Mobile SDK 1.x.

`PowerAuthBiometricPrompt` also contains the Android-specific `promptSubtitle` property.

## End-to-End Encryption

The end-to-end encryption API now uses one stateful encryptor for one request and response exchange. The acquisition methods are asynchronous. The request and response bodies use `Uint8List`.

```dart
final encryptor = await powerAuth.getEncryptorForActivationScope();
try {
    final encrypted = await encryptor.encryptRequest(requestBody);
    final response = await sendRequest(
        encrypted.requestBody,
        encrypted.requestHeaders,
    );
    final clearResponse = await encryptor.decryptResponse(response.bodyBytes);
} finally {
    await encryptor.release();
}
```

Acquire a new encryptor for each exchange. Use the same encryptor to encrypt the request and decrypt its response. The following types were removed:

- `PowerAuthCryptogram`
- `PowerAuthEncryptedRequestData`
- `PowerAuthDecryptor`
- `PowerAuthEncryptionHttpHeader`
- `PowerAuthDataFormat`

## Secure Vault

`fetchEncryptionKey()` now returns `Uint8List` and is deprecated. It works only with protocol 3.3.

For protocol 4.0, use `fetchSecureVaultKey()`. Derive all required keys and release the native key in a `finally` block:

```dart
final vaultKey = await powerAuth.fetchSecureVaultKey(
    authentication,
    PowerAuthSecureVaultKeyId.knowledge,
);
try {
    final key = await vaultKey.deriveKey(1000, 32);
} finally {
    await vaultKey.release();
}
```

Do not persist derived keys. Use a unique derivation index for every purpose or data set, never reuse a key for both encryption and authentication, and maintain a registry of indices when the application derives multiple keys. The legacy API is intended only for decrypting old local data before re-encrypting it with a new protocol 4.0 key.

## Activation State and Errors

`PowerAuthActivationState.created` was removed because the server does not return this state to a mobile client. Handle `PowerAuthActivationState.unknown` so that a new server state does not appear as a removed activation.

The following error codes were removed:

- `authenticationError`
- `responseError`
- `invalidEncryptor`

Transport failures use `networkError`. Server failures can include stable response details in `PowerAuthException.errorData`. An invalid or released native object uses `invalidNativeObject`. Version 2.0 adds `wrongSignature`, `upgradeSdk`, `invalidLogLevel`, `other`, and `flutterError`.

## Native Object Lifetime

Native object identifiers are no longer public. Call `release()` on `PowerAuthPassword`, `PowerAuthPasswordChangeData`, `PowerAuthEncryptor`, and `PowerAuthSecureVaultKey` when you no longer need the object. An expired, consumed, or released object reports `PowerAuthErrorCode.invalidNativeObject` if you use it again.

## Read Next

- [Configuration](Configuration.md)
- [Troubleshooting](Troubleshooting.md)
