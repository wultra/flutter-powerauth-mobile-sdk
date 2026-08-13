# Data Signing

The main feature of the PowerAuth protocol is data signing. PowerAuth supports the following types of signatures:

- [Symmetric Multi-Factor Authentication Code](#symmetric-multi-factor-authentication-code): Suitable for most operations, such as login, payment approval, or confirming changes in settings.
- [Symmetric Offline Multi-Factor Authentication Code](#symmetric-offline-multi-factor-authentication-code): Suitable for operations where the authentication code is validated over an out-of-band channel.
- [Asymmetric Private Key Signature](#sign-data-with-device-private-key): Suitable for documents where a strong one-sided signature is required.
- [Verify Server-Signed Data](#verify-server-signed-data): Suitable for receiving arbitrary data from the server.

## Authentication Codes

### Symmetric Multi-Factor Authentication Code

Create a `PowerAuthAuthentication` object that contains the required authentication factors:

```dart
// 2FA authentication code with the possession factor and a PIN.
final password = await PowerAuthPassword.fromString(
    "1234",
    destroyOnUse: false,
);
final authentication = PowerAuthAuthentication.password(
    password,
);
```

This password is reusable so request-body and query-parameter operations can share the same authentication object. Always release a reusable password in a `finally` block.

For a request with a body, pass the raw body bytes to `authenticationHeaderForRequestWithBody()`. For a request with query parameters, use `authenticationHeaderForRequestWithParams()`:

```dart
final body = Uint8List.fromList(
    utf8.encode(jsonEncode({"payment": "yes"})),
);
const params = {
    "param1": "value1",
    "param2": "value2",
};

try {
    final bodyHeader = await powerAuth.authenticationHeaderForRequestWithBody(
        authentication,
        "POST",
        "/payment/create",
        body,
    );
    final bodyHeaderName = bodyHeader.name;
    final bodyHeaderValue = bodyHeader.value;

    final paramsHeader = await powerAuth.authenticationHeaderForRequestWithParams(
        authentication,
        "GET",
        "/payment/create",
        params,
    );
    final paramsHeaderName = paramsHeader.name;
    final paramsHeaderValue = paramsHeader.value;
} catch (e) {
    // Handle an error.
} finally {
    await password.release();
}
```

Each result is an HTTP header. Add its `name` and `value` to the corresponding request.

To use biometry, create a biometric authentication object:

```dart
final authentication = PowerAuthAuthentication.biometry(
    biometricPrompt: PowerAuthBiometricPrompt(
        promptMessage: "Authenticate to process the payment",
        promptTitle: "Authenticate",       // Android only
        fallbackButtonTitle: "Enter PIN", // iOS only
    ),
);

try {
    final header = await powerAuth.authenticationHeaderForRequestWithBody(
        authentication,
        "POST",
        "/payment/create",
        body,
    );
} on PowerAuthException catch (e) {
    if (e.code == PowerAuthErrorCode.biometryCancel) {
        // The user canceled the biometric dialog.
    } else if (e.code == PowerAuthErrorCode.biometryFallback) {
        // The user selected the fallback button on iOS.
    } else {
        // Handle a different error.
    }
}
```

#### Request Synchronization

It is recommended that your application executes only one authenticated request at a time. Authentication codes use a counter as logical time, so the server must validate requests in the same order in which the SDK creates them.

### Symmetric Offline Multi-Factor Authentication Code

An offline authentication code is a short string that a user can transfer through a separate channel. Pass the nonce as a Base64-encoded string and the body as raw bytes:

```dart
final authentication = PowerAuthAuthentication.password(
    await PowerAuthPassword.fromString("1234"),
);
final body = Uint8List.fromList(utf8.encode(jsonEncode(operation)));

try {
    final authenticationCode = await powerAuth.offlineSignature(
        authentication,
        "/confirm/offline/operation",
        nonce,
        body,
    );
    print("Offline authentication code: $authenticationCode");
} catch (e) {
    // Handle an error.
}
```

Show the calculated code to the user. The user can enter it in the other application that validates the operation.

## Digital Signatures

Digital signatures are another form of data authentication supported by the PowerAuth protocol. The SDK provides one interface for computing and verifying digital signatures and MAC tokens.

### Signature Key Identifiers

The following key categories are available:

- **Master** public keys verify data signed by the server and do not require an activation.
- **Server** public keys are personalized for an activation and verify data signed by the server.
- **Device** private and public keys belong to an activation and sign or verify data on the device.
- **MAC** keys are personalized symmetric keys that verify MACs calculated by the server.

| Key identifier | Key type | Signature | Activation | Sign | Verify |
|---|---|---|---|---|---|
| `master` | Any | Any or hybrid | No | No | Yes |
| `masterEc` | EC | ECDSA | No | No | Yes |
| `masterMlDsa` | ML-DSA | ML-DSA | No | No | Yes |
| `server` | Any | Any or hybrid | Yes | No | Yes |
| `serverEc` | EC | ECDSA | Yes | No | Yes |
| `serverMlDsa` | ML-DSA | ML-DSA | Yes | No | Yes |
| `device` | Any | Any or hybrid | Yes | Yes | Yes |
| `deviceEc` | EC | ECDSA | Yes | Yes | Yes |
| `deviceMlDsa` | ML-DSA | ML-DSA | Yes | Yes | Yes |
| `macPersonalized` | MAC | KMAC | Yes | No | Yes |

EC keys are always available. ML-DSA keys are available only with `PowerAuthAlgorithm.p384l3` and `PowerAuthAlgorithm.p384l5`. MAC keys are available with every algorithm except `PowerAuthAlgorithm.legacy`.

<!-- begin box warning -->
Selecting a key without its exact type, such as `master`, can select both EC and ML-DSA keys. Because a hybrid raw-signature format is not standardized, generic key identifiers are supported only by the JWS functions. Use an exact key type for raw digital signatures.
<!-- end -->

### Sign Data With Device Private Key

An asymmetric private key signature uses a device private key from the Secure Vault. The user must authenticate with at least two factors before the SDK can use the key. Select an exact device key type:

```dart
final authentication = PowerAuthAuthentication.password(
    await PowerAuthPassword.fromString("1234"),
);
final data = Uint8List.fromList(utf8.encode("hello"));

try {
    final signature = await powerAuth.calculateDigitalSignature(
        authentication,
        data,
        PowerAuthSignatureKeyId.deviceMlDsa,
    );
    // Use data and signature.
} catch (e) {
    // Handle an authentication or network error.
}
```

Biometric authentication can also access the device private key when the SDK is not configured with `PowerAuthAlgorithm.legacy`.

### Create JSON Web Signature With Device Private Key

The device private key can also create a [JSON Web Signature (JWS)](https://www.rfc-editor.org/rfc/rfc7515). The following example creates both a non-compact JWS from generic data and a compact signed JWT. It uses a reusable password so both operations can share the same authentication object:

```dart
final password = await PowerAuthPassword.fromString(
    "1234",
    destroyOnUse: false,
);
final authentication = PowerAuthAuthentication.password(
    password,
);
try {
    final data = Uint8List.fromList(utf8.encode("hello"));
    final jws = await powerAuth.calculateJwsSignature(
        authentication,
        data,
        null,  // Do not add "typ" to the JWS protected header.
        false, // Return a full JWS object.
        PowerAuthSignatureKeyId.deviceMlDsa,
    );

    final claimsData = Uint8List.fromList(utf8.encode(jsonEncode({
        "sub": "user-id",
        "first_name": "John",
        "last_name": "Appleseed",
    })));
    final jwt = await powerAuth.calculateJwsSignature(
        authentication,
        claimsData,
        "JWT",
        true, // Return the compact JWT form.
        PowerAuthSignatureKeyId.deviceMlDsa,
    );
} finally {
    await password.release();
}
```

### Verify Server-Signed Data

Use `verifyDigitalSignature()` to verify raw data. Select the exact server key that signed the data:

```dart
try {
    await powerAuth.verifyDigitalSignature(
        signature,
        data,
        PowerAuthSignatureKeyId.serverMlDsa,
    );
    // The signature is valid.
} on PowerAuthException catch (e) {
    if (e.code == PowerAuthErrorCode.wrongSignature) {
        // The signature is not valid.
    } else {
        // Handle another failure, such as a missing activation.
    }
}
```

The method completes without a result when the signature is valid and reports `PowerAuthErrorCode.wrongSignature` when verification fails.

#### Verify Data Encoded in a QR Code

To verify data authenticated by the server with an activation-personalized MAC, use `macPersonalized`:

```dart
try {
    await powerAuth.verifyDigitalSignature(
        signature,
        data,
        PowerAuthSignatureKeyId.macPersonalized,
    );
    // The MAC is valid.
} on PowerAuthException catch (e) {
    if (e.code == PowerAuthErrorCode.wrongSignature) {
        // The MAC is not valid.
    }
}
```

### Verify JSON Web Signature

To verify a non-compact JWS created by the server, use:

```dart
await powerAuth.verifyJwsSignature(
    serverJws,
    false, // Expect a full JWS object.
    true,  // Require all selected signatures to be valid.
    PowerAuthSignatureKeyId.server,
);
```

The `verifyJwsSignature()` parameters have the following meaning:

- `signature` contains the JWS- or JWT-signed data.
- `compact` indicates whether `signature` contains a compact JWT (`true`) or a full JWS object (`false`).
- `strict` requires all selected keys to verify their corresponding signatures when `true`. This is the recommended setting. When `false`, verification succeeds if at least one selected key matches a valid signature, but invalid or mismatched signatures still cause an error.
- `signatureKeyId` selects the keys used for verification. JWS verification does not support `PowerAuthSignatureKeyId.macPersonalized`.

<!-- begin box warning -->
A compact JWT contains only one signature. Use an exact key type, such as `deviceEc`, `deviceMlDsa`, `serverEc`, or `serverMlDsa`, for compact signatures. Generic identifiers such as `device` or `server` can select both EC and ML-DSA keys with `PowerAuthAlgorithm.p384l3` and `PowerAuthAlgorithm.p384l5`; use those identifiers with non-compact JWS.

Setting `strict` to `false` is generally not recommended. An attacker could remove or replace a stronger post-quantum signature with a weaker signature without detection.
<!-- end -->

### Creating Certificate Signing Request

Use `createCertificateSigningRequest()` to create an X.509 certificate signing request in PEM format. Prefix every subject alternative name with its type:

```dart
final authentication = PowerAuthAuthentication.password(
    await PowerAuthPassword.fromString("1234"),
);

final csr = await powerAuth.createCertificateSigningRequest(
    authentication,
    {
        "CN": "wultra.com",
        "O": "Wultra",
        "C": "CZ",
    },
    [
        "IP: 192.168.1.10",
        "email: admin@example.com",
    ],
    PowerAuthSignatureKeyId.deviceMlDsa,
);
```

Biometric authentication can also create a CSR when the SDK is not configured with `PowerAuthAlgorithm.legacy`.

### Getting Device Public Keys

Use `exportDevicePublicKeys()` to export public keys for the current activation:

```dart
final keys = await powerAuth.exportDevicePublicKeys(
    PowerAuthDevicePublicKeyFormat.der,
);
for (final key in keys) {
    print("${key.keyAlgorithm}: ${base64Encode(key.keyData)}");
}
```

Available formats:

- `PowerAuthDevicePublicKeyFormat.der` exports a binary X.509 SubjectPublicKeyInfo structure.
- `PowerAuthDevicePublicKeyFormat.raw` exports EC keys in ANSI X9.63 format and ML-DSA keys as raw public-key bytes.

## Read Next

- [Password Management](Password-Management.md)
