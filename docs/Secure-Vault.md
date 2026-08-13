# Secure Vault

Secure Vault provides a base key derivation key after successful two-factor authentication. This base key is not an encryption or MAC key. Use it only to derive purpose-specific keys. This API requires an activation that uses PowerAuth protocol 4.0.

PowerAuth SDK provides two base keys:

- `PowerAuthSecureVaultKeyId.knowledge` is available after possession and knowledge authentication.
- `PowerAuthSecureVaultKeyId.knowledgeOrBiometry` is available after possession and knowledge authentication or possession and biometry authentication.

<!-- begin box warning -->
PowerAuth Server must permit the selected authentication factors for the Secure Vault unlock operation.
<!-- end -->

## Obtain and Derive a Key

Use `fetchSecureVaultKey()` to obtain a native-backed base key. Derive all required keys and release the base key as soon as possible.

```dart
final authentication = PowerAuthAuthentication.password(
    await PowerAuthPassword.fromString("1234"),
);

final vaultKey = await powerAuth.fetchSecureVaultKey(
    authentication,
    PowerAuthSecureVaultKeyId.knowledge,
);

try {
    // Derive a 32-byte key for application-specific index 1000.
    final key = await vaultKey.deriveKey(1000, 32);
    // Use the derived key without storing it on the device.
} finally {
    await vaultKey.release();
}
```

The minimum derived key size is 16 bytes. The base key remains stable for the lifetime of the activation.

## Security Recommendations

- Do not store derived keys on the device. Acquire the base key when needed and derive a key for each specific purpose.
- Release the base key as soon as all required keys have been derived.
- Never reuse one derived key for multiple purposes, such as both encryption and authentication.
- Derive different keys with different indices for separate data sets and purposes.
- Maintain a registry of derivation indices if the application uses multiple keys, to prevent accidental key reuse.

## Legacy API

`fetchEncryptionKey()` is deprecated and works only with PowerAuth protocol 3.3. It now returns raw bytes as `Uint8List`.

```dart
final key = await powerAuth.fetchEncryptionKey(authentication, 1000);
```

This legacy method is useful for decrypting local data created by an older SDK. Migrate the activation to protocol 4.0, decrypt the old data with the legacy key, and re-encrypt it with a key derived from `fetchSecureVaultKey()`.

## Read Next

- [Token Based Authentication](Token-Based-Authentication.md)
