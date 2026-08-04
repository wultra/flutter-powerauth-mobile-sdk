# End-To-End Encryption

PowerAuth SDK supports two end-to-end encryption scopes:

- In the **application** scope, encryption is available without an activation.
- In the **activation** scope, encryption requires a valid activation. You can combine this scope with a [PowerAuth Symmetric Multi-Factor Authentication Code](Data-Signing.md#symmetric-multi-factor-authentication-code) in encrypt-then-sign mode.

Use one `PowerAuthEncryptor` for one request and response exchange. The same object encrypts the request and decrypts its response.

The following example shows a complete exchange:

```dart
// Use getEncryptorForApplicationScope() if the endpoint does not require an activation.
final encryptor = await powerAuth.getEncryptorForActivationScope();

try {
    // Serialize the request payload to bytes.
    final requestBody = Uint8List.fromList(
        utf8.encode(jsonEncode({
            "message": "Hello World!",
            "code": "HELLO",
        })),
    );

    // Encrypt the request.
    final encryptedRequest = await encryptor.encryptRequest(requestBody);

    // Add all encryption headers to the HTTP request.
    final headers = <String, String>{
        for (final header in encryptedRequest.requestHeaders)
            header.name: header.value,
    };

    final configuration = await powerAuth.configuration;
    final url = Uri.parse("${configuration.baseEndpointUrl}/$endpoint");
    final response = await http.post(
        url,
        headers: headers,
        body: encryptedRequest.requestBody,
    );

    // Decrypt the raw response body with the same encryptor.
    final clearResponse = await encryptor.decryptResponse(response.bodyBytes);
    final responseObject = jsonDecode(utf8.decode(clearResponse));
} finally {
    await encryptor.release();
}
```

Acquire a new encryptor for each exchange. After `encryptRequest()`, the object cannot encrypt another request. After `decryptResponse()`, the object is no longer valid.

If the server returns a non-success HTTP status, process the PowerAuth REST error response. Do not pass an unencrypted error response to `decryptResponse()`.

Implementing application-specific end-to-end encryption is a non-trivial task. Contact Wultra before deployment if you need guidance for your scenario.

## Sign an Encrypted Request

To use encrypt-then-sign mode, first encrypt the request body. Then calculate the authentication header from `encryptedRequest.requestBody`:

```dart
final authenticationHeader =
    await powerAuth.authenticationHeaderForRequestWithBody(
        authentication,
        "POST",
        uriId,
        encryptedRequest.requestBody,
    );
```

For an activation-scoped encryptor, the authentication header contains the information that the server needs to decrypt the request. In this case, you do not need to add `encryptedRequest.requestHeaders`.

## Native Object Lifetime

The encryptor owns a native object. Apply these rules:

- Call `release()` in a `finally` block.
- Repeated calls to `release()` are safe.
- Deconfiguration of the parent `PowerAuth` instance invalidates the encryptor.
- A released or consumed encryptor reports `PowerAuthErrorCode.invalidNativeObject` if you use it again.

## Read Next

- [Secure Vault](Secure-Vault.md)
