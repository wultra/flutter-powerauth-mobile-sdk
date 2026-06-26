# End-To-End Encryption

The PowerAuth SDK supports two basic modes of end-to-end encryption, based on the ECIES scheme:

- In an "application" scope, the encryptor can be acquired and used during the whole lifetime of the application.
- In an "activation" scope, the encryptor can be acquired only if the `PowerAuth` instance has a valid activation. The encryptor created for this mode is cryptographically bound to the parameters agreed upon during the activation process. You can combine this encryption with [PowerAuth Symmetric Multi-Factor Signature](Data-Signing.md#symmetric-multi-factor-signature) in "encrypt-then-sign" mode.

For both scenarios, you need to acquire the `PowerAuthEncryptor` object, which will then provide an interface for the request encryption and the response decryption.

The following steps are typically required for a full E2EE request and response processing:

1. Acquire the right encryptor from the `PowerAuth` instance. For example:
   ```dart
   // Encryptor for "application" scope.
   final encryptor = powerAuth.getEncryptorForApplicationScope();
   // ...or similar, for an "activation" scope.
   final encryptor = powerAuth.getEncryptorForActivationScope();
   ```

1. Encode the plaintext body into a format that best fits your purpose. You can use plain string or Base64 encoded data:
   ```dart
   String requestData;
   PowerAuthDataFormat requestDataFormat;
   if (binaryData) {
       // If you need to encrypt the binary data, such as an image, then you can encode it as BASE64
       requestDataFormat = PowerAuthDataFormat.base64;
       requestData = 'iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==';
   } else {
       // Regular JSON request can be encrypted as a plain string
       requestDataFormat = PowerAuthDataFormat.utf8;
       requestData = jsonEncode({
          "message": "Hello World!",
          "code": "HELLO"
       });
   }
   ```

1. Encrypt the plaintext request data:
   ```dart
   // 2nd parameter is optional, if not provided, then 'UTF8' is applied.
   final encryptedData = await encryptor.encryptRequest(requestData, requestDataFormat);
   // Keep decryptor object for later to properly decrypt the response from the server.
   // The decryptor is always unique for each request.
   final decryptor = encryptedData.decryptor;
   // Cryptogram contains encrypted data
   final cryptogram = encryptedData.cryptogram;
   // Content of HTTP header
   final header = encryptedData.header;
   ```

1. Construct and execute the HTTP request:
   ```dart
   // Headers
   final headers = { header.name: header.value };
   // Request body
   // This may depend on the endpoint, but the cryptogram is typically serialized as-is, or it's embedded
   // in another structure, such as:
   // {
   //     requestObject: cryptogram
   // }
   final body = jsonEncode(encryptedData.cryptogram.toMap());
   // Fetch data
   final configuration = await sdk.configuration;
   final url = Uri.parse("${configuration!.baseEndpointUrl}/$endpoint");
   final response = await http.post(url, headers: headers, body: body);
   // The response object is typically also PowerAuthCryptogram
   final responseObject = jsonDecode(response.body) as Map<String, dynamic>;
   ```

1. Now, decrypt the response. Depending on what type of data you expect, you can specify `ut8` or `base64` output data format:
   ```dart
   final responseDataFormat = PowerAuthDataFormat.utf8;
   // 2nd parameter is optional, if not provided, then 'utf8' is applied.
   final decryptedData = await decryptor.decryptResponse(PowerAuthCryptogram.fromMap(response), responseDataFormat);
   final decryptedObject = jsonDecode(decryptedData);
   ```

## Sign encrypted request

If the endpoint require also [PowerAuth Signature](Data-Signing.md#symmetric-multi-factor-signature), then you have to encrypt your request data first, construct the request body with using the cryptogram and then sign the whole body. In this case, the encryption header can be omitted because the header from the signature calculation already contains enough information to process the request on the server.

## Native object lifetime

Both `PowerAuthEncryptor` and `PowerAuthDecryptor` implementations use underlying native objects with a limited lifetime behind the scenes. The following rules are applied:

- `PowerAuthEncryptor`
  - Releases its internal native object after 5 minutes of inactivity. If used again, then the native object is re-created automatically.
  - The object is released when its parent `PowerAuth` instance is deconfigured. After this, encryption is no longer available.
  - If the encryptor is activation-scoped and the parent `PowerAuth` instance has no activation, then encryption is not available.
  - You can use the `canEncryptRequest()` function to test whether the encryption is available.

- `PowerAuthDecryptor`
  - Decryption is always one-time operation, so by callling `decryptResponse()` is underlying native object released.
  - The object is released when its parent `PowerAuth` instance is deconfigured.
  - If the decryptor is activation-scoped and the parent `PowerAuth` instance has no activation, then decryption is not available.
  - Releases its internal native object after 5 minutes of inactivity.
  - You can use the `canDecryptResponse()` function to test whether the decryption is available.

Both objects provide a `release()` function to release the underlying native object manually.

## Read Next

- [Secure Vault](Secure-Vault.md)
