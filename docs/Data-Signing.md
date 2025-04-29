# Data Signing

The main feature of the PowerAuth protocol is data signing. PowerAuth has three types of signatures:

- **Symmetric Multi-Factor Signature**: Suitable for most operations, such as login, new payment, or confirming changes in settings.
- **Asymmetric Private Key Signature**: Suitable for documents where a strong one-sided signature is desired.
- **Symmetric Offline Multi-Factor Signature**: Suitable for very secure operations, where the signature is validated over the out-of-band channel.
- **Verify server signed data**: Suitable for receiving arbitrary data from the server.

## Symmetric Multi-Factor Signature

To sign request data, you need to first obtain user credentials (password, PIN code, Touch ID scan) from the user. The task of obtaining the user credentials is used in more use cases covered by the SDK. The core class is `PowerAuthAuthentication` that holds information about the used authentication factors:

```dart
// 2FA signature, uses device-related key and user PIN code
final auth = PowerAuthAuthentication.password(PowerAuthPassword.fromString("1234));
```

When signing `POST`, `PUT`, or `DELETE` requests, use request body bytes (UTF-8) as request data and the following code:

```dart
// 2FA signature, uses device-related key and user PIN code
final auth = PowerAuthAuthentication.password(PowerAuthPassword.fromString("1234"));

// Sign POST call with provided data made to URI with custom identifier "/payment/create"
try {
    final signature = await powerAuth.requestSignature(auth, "POST", "/payment/create", "{jsonbody: \"yes\"}");
    final httpHeaderKey = signature.key;
    final httpHeaderValue = signature.value;
} catch (e) {
    // In case of invalid configuration, invalid activation state, or corrupted state data
}
```

When signing `GET` requests, use the same code as above with normalized request data as described in the specification, or (preferably) use the following helper method:

```dart
// 2FA signature, uses device-related key and user PIN code
final auth = PowerAuthAuthentication.password(PowerAuthPassword.fromString("1234"));

// Sign GET call with provided query parameters made to URI with custom identifier "/payment/create"
const params = {
    "param1": "value1",
    "param2": "value2"
};

try {
    final signature = await powerAuth.requestGetSignature(auth, "/payment/create", params);
    final httpHeaderKey = signature.key;
    final httpHeaderValue = signature.value;
} catch(e) {
    // In case of invalid configuration, invalid activation state, or corrupted state data
}
```

To sign data with biomtry, simply create a different authentication object:

```dart
// 2FA signature, uses device-related key and biometry
final auth = PowerAuthAuthentication.biometry(
  biometricPrompt: PowerAuthBiometricPrompt(
    promptMessage: 'Authenticate to process payment',   // Required on both platforms
    promptTitle: 'Authenticate',    // Android specific, not used on iOS
    fallbackButtonTitle: 'Enter PIN'     // iOS specific, if provided, then the fallback button is displayed
  )
);

// Sign POST call with provided data made to URI with custom identifier "/payment/create"
try {
    final signature = await powerAuth.requestSignature(auth, "POST", "/payment/create", "{jsonbody: \"yes\"}");
    final httpHeaderKey = signature.key;
    final httpHeaderValue = signature.value;
} on PowerAuthException catch (e) {
    if (e.code == PowerAuthErrorCode.biometryCancel) {
        // User did cancel the dialog
    } else if (e.code == PowerAuthErrorCode.biometryFallback) {
        // iOS specific, can occur only if you provide the fallback button
    } else {
        // other errors
    }
} catch (e) {
  // Handle unexpected errors
}
```

### Request Synchronization

It is recommended that your application execute only one signed request at a time. The reason for that is that our signature scheme uses a counter as a representation of logical time. In other words, the order of request validation on the server is very important. If you issue more than one signed request at the same time, then the order is not guaranteed, and therefore, one of the requests may fail.

## Asymmetric Private Key Signature

Asymmetric Private Key Signature uses a private key stored in the PowerAuth secure vault. In order to unlock the secure vault and retrieve the private key, the user has to first authenticate using the symmetric multi-factor signature with at least two factors. This mechanism protects the private key on the device - the server plays the role of a "doorkeeper" and holds the vault unlock key.

You could either sign a UTF-8 string or a Base64-encoded data. Fill a proper `dataFormat` parameter to specify the data format.

This process is completely transparent on the SDK level. To compute an asymmetric private key signature, request user credentials (password, PIN) and use the following code:

```dart
// 2FA signature, uses device-related key and user PIN code
final auth = PowerAuthAuthentication.password(PowerAuthPassword.fromString("1234"));

// Unlock the secure vault, fetch the private key, and perform data signing
try {
    final dataToSign = "N9yHkF5zSks="; // base64 encoded data to sign
    final dataFormat = "BASE64"; // data format, UTF8 in case of plain string
    final signature = await powerAuth.signDataWithDevicePrivateKey(auth, dataToSign, dataFormat);
    // Send data and signature to the server
} catch(e) {
    // Authentication or network error
}
```

## Symmetric Offline Multi-Factor Signature

This type of signature is very similar to [Symmetric Multi-Factor Signature](#symmetric-multi-factor-signature), but the result is provided in the form of a simple, human-readable string (unlike the online version, where the result is an HTTP header). To calculate the signature, you need a typical `PowerAuthAuthentication` object to define all required factors, nonce, and data to sign. The `nonce` and `data` should also be transmitted to the application over the OOB channel (for example, by scanning a QR code). Then the signature calculation is straightforward:

```dart
// 2FA signature, uses device-related key and user PIN code
final auth = PowerAuthAuthentication.password(PowerAuthPassword.fromString("1234"));
try {
    final signature = await _powerAuth.offlineSignature(auth, "/confirm/offline/operation", data, nonce);
    print("Signature is " + signature);
} catch (e) {
    // In case of invalid configuration, invalid activation state, or other error
}
```

The application has to show the calculated signature to the user now, and the user has to retype that code into the web application for verification.

## Verify Server-Signed Data

This task is useful whenever you need to receive arbitrary data from the server and you need to be able to verify that the server has issued the data. The PowerAuthSDK provides a high-level method for validating data and the associated signature:  

```dart
// Validate data signed with the master server key
try {
    final isVerified = await _powerAuth.verifyServerSignedData(data, signature, true);
    print('Verified: $isVerified');
} catch (e) {
    // API error
}

// Validate data signed with the personalized server key
try {
    final isVerified = await _powerAuth.verifyServerSignedData(data, signature, false);
    print('Verified: $isVerified');
} catch (e) {
    // API error
}
```

## Read Next

- [Password Change](Password-Change.md)
