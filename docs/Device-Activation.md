# Device Activation

After you configure the SDK, you are ready to make your first activation.

## Activation via Activation Code

The original activation method uses a one-time activation code generated in PowerAuth Server. To create an activation using this method, some external application (Internet banking, ATM application, branch/kiosk application) must generate an activation code for you and display it (as text or in a QR code).

Use the following code to create an activation once you have an activation code:

```dart
final name = "Petr's iPhone 7"; // users phone name
final activationCode = "VVVVV-VVVVV-VVVVV-VTFVA"; // let user type or QR-scan this value

// Create activation object with given activation code.
final activation = PowerAuthActivation.fromActivationCode(activationCode: activationCode, name: name);
try {
    final result = await powerAuth.createActivation(activation);
    // No error occurred, proceed to credentials entry (PIN prompt, Enable Biometry, ...) and persist the activation
    // The 'result' contains 'activationFingerprint' property, representing the device public key - it may be used as visual confirmation
} on PowerAuthException catch (e) {
    // handle powerauth exception
} catch (e) {
    // unknown exception
}
```

### Additional Activation OTP

If an [additional activation OTP](https://github.com/wultra/powerauth-crypto/blob/develop/docs/Additional-Activation-OTP.md) is required to complete the activation, then use the following code to configure the `PowerAuthActivation` object:

```dart
final name = "Petr's iPhone 7"; // users phone name
final activationCode = "VVVVV-VVVVV-VVVVV-VTFVA"; // let user type or QR-scan this value

// Create activation object with given activation code.
final activation = PowerAuthActivation.fromActivationCode(
    activationCode: activationCode, 
    name: name,
    additionalActivationOtp: '123456' // OTP retrieved via other channel (SMS, for example)
);
// The rest of the activation routine is the same.
```

<!-- begin box warning -->
Be aware that OTP can be used only if the activation is configured for `ON_KEY_EXCHANGE` validation on the PowerAuth server. See our [crypto documentation for details](https://github.com/wultra/powerauth-crypto/blob/develop/docs/Additional-Activation-OTP.md#regular-activation-with-otp).
<!-- end -->

## Activation via Custom Credentials

You may also create an activation using any custom login data - it can be anything that the server can use to obtain the user ID to associate with a new activation. Since the credentials are custom, the server's implementation must be able to process such a request. The custom activation no longer requires a custom activation endpoint.

Use the following code to create an activation using custom credentials:

```dart
// Create a new activation with a given device name and custom login credentials
final name = "Petr's iPhone 7"; // users phone name
final credentials = {
    "username": "john.doe@example.com",
    "password": "YBzBEM"
};

// Create activation object with given credentials.
final activation = PowerAuthActivation.fromIdentityAttributes(identityAttributes: creds, name: name);

// Create a new activation with the just-created activation object
try {
    final result = await powerAuth.createActivation(activation);
    // No error occurred, proceed to credentials entry (PIN prompt, Enable Biometry, ...) and persist the activation
    // The 'result' contains 'activationFingerprint' property, representing the device public key - it may be used as visual confirmation
} on PowerAuthException catch (e) {
    // handle powerauth exception
} catch (e) {
    // unknown exception
}
```

Note that by using weak identity attributes to create an activation, the resulting activation confirms a "blurry identity". This may greatly limit the legal weight and usability of a signature. We recommend using a strong identity verification before activation can actually be created.


## Customize Activation

You can set additional properties to the `PowerAuthActivation` object before any type of activation is created. For example:

```dart
// Custom attributes that can be processed before the activation is created on the PowerAuth Server.
// The dictionary may contain only values that can be serialized to JSON.
final customAttributes = {
    "isNowPrimaryActivation" : true,
    "otherActivationIds" : [
        "e43f5f99-e2e9-49f2-bcae-5e32a5e96d22",
        "41dd704c-65e6-4d4b-b28f-0bc0e4eb9715"
    ]
};

// Create the activation object
final activation = PowerAuthActivation.fromActivationCode(
    activationCode: "45AWJ-BVACS-SBWHS-ABANA", 
    name: "deviceName",
    customAttributes: customAttributes,
    extras: "EXTRA_FLAGS" // Extra flags that will be associated with the activation record on PowerAuth 
);
// Create a new activation as usual
try {
    final result = await powerAuth.createActivation(activation);
    // continue with the flow
} catch (e) {
    // process eror
}
```  

## Persisting Activation Data

After you create an activation using one of the methods mentioned above, you need to persist the activation to use the provided user credentials to store the activation data on the device. 

```dart
final auth = PowerAuthAuthentication.persistWithPasswordAndBiometry(
    password: PowerAuthPassword.fromString("1234"), 
    biometricPrompt: {
        // The `PowerAuthBiometricPrompt` object is required on the Android platform in case that
        // `biometryConfiguration.authenticateOnBiometricKeySetup` is true.
        // You can provide an undefined prompt object in case that flag is false.
        promptTitle: 'Please authenticate with biometry',
        promptMessage: 'Please authenticate to create an activation supporting biometry'
    }
);
try {
  await powerAuth.persistActivation(auth);
} catch (e) {
    // happens only in case the SDK was not configured or activation is not in a state to be persisted
}
```


## Validating User Inputs

The mobile SDK provides a couple of functions in the `PowerAuthActivationCodeUtil` helper, helping with user input validation. You can:

- Parse activation code when it's scanned from a QR code
- Validate the whole code at once
- Auto-correct characters typed on the fly

### Validating Scanned QR Code

To validate an activation code scanned from a QR code, you can use `PowerAuthActivationCodeUtil.parseActivationCode(code)` function. You have to provide the code with or without the signature part. For example:

```dart
final scannedCode = "VVVVV-VVVVV-VVVVV-VTFVA#aGVsbG8......gd29ybGQ=";
try {
  final code = await PowerAuthActivationCodeUtil.parseActivationCode(scannedCode);
  if (code.activationSignature == null) {
     // QR code should contain a signature
     return
  }
} catch(e) {
  // not valid
}
```

Note that the signature is only formally validated in the function above. The actual signature verification is performed in the activation process, or you can do it on your own:

```dart
final scannedCode = "VVVVV-VVVVV-VVVVV-VTFVA#aGVsbG8......gd29ybGQ=";
try {
  final code = await PowerAuthActivationCodeUtil.parseActivationCode(scannedCode);
  if (code.activationSignature != null) {
     await powerAuth.verifyServerSignedData(code.activationCode, code.activationSignature, true);
     // valid
  }
} catch(e) {
  // not valid
}
```

### Validating Entered Activation Code

To validate an activation code at once, you can call the `PowerAuthActivationCodeUtil.validateActivationCode()` function. You have to provide the code without the signature part. For example:

```dart
final isValid = await PowerAuthActivationCodeUtil.validateActivationCode("VVVVV-VVVVV-VVVVV-VTFVA");
final isInvalid = await PowerAuthActivationCodeUtil.validateActivationCode("VVVVV-VVVVV-VVVVV-VTFVA#aGVsbG8gd29ybGQ=");
```

If your application is using your own validation, then you should switch to the functions provided by the SDK. All activation codes contain a checksum, so it's possible to detect mistyped characters before you start the activation. Check our [Activation Code](https://github.com/wultra/powerauth-crypto/blob/develop/docs/Activation-Code.md) documentation for more details.

### Auto-Correcting Typed Characters

You can implement auto-correcting of typed characters by using `PowerAuthActivationCodeUtil.correctTypedCharacter()` function in screens, where the user is supposed to enter an activation code. This technique is possible due to the fact that Base32 is constructed so that it doesn't contain visually confusing characters. For example, `1` (number one) and `I` (capital I) are confusing, so only `I` is allowed. The benefit is that the provided function can correct typed `1` and translate it to `I`.

Here's an example of how to iterate over the string and validate it character by character:


```dart
/// Returns corrected code
Future<String> validateAndCorrectCharacters(String code) async {
  var result = "";
  for (var i = 0; i < code.length; i++) {
    try {
      final corrected = await PowerAuthActivationCodeUtil.correctTypedCharacter(code.codeUnitAt(i));
      result += String.fromCharCode(corrected);
    } catch (e) {
      print('invalid character: ${code.codeUnitAt(i)}');
    }
  }
  print('Corrected: $result');
  return result;
}
```

## Read Next

- [Requesting Device Activation Status](Requesting-Device-Activation-Status.md)
