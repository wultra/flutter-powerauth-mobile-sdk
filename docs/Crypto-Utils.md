# Crypto Utils

Flutter PowerAuth Mobile SDK also provides useful cryptographic utility functions:
- Generate cryptographically secure random bytes
- Compute SHA-256 hashes

## Import
Use the main package entry point:
```dart
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
```

## randomBytes(length)

Generate cryptographically secure random bytes of the requested length.

Params:
- `length`: number of bytes to generate. Must be a positive integer (> 0).

Returns:
- Future that completes with a `Uint8List` containing length random bytes.

Errors:
- Throws a PowerAuthException with `PowerAuthErrorCode.wrongParameter` if length <= 0.

Example:
```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';

Future<void> generateNonce() async {
  try {
    // Generate 16 random bytes and encode to Base64 for transport or logging
    final Uint8List nonce = await PowerAuthCryptoUtils.randomBytes(16);
    final String base64Nonce = base64Encode(nonce);
    print('Nonce (Base64): $base64Nonce');
  } on PowerAuthException catch (e) {
    // Handle invalid length or other platform errors
    print('Failed to generate random bytes: ${e.code} ${e.message}');
  }
}
```

## hashSha256(data)

Compute the SHA-256 digest of input bytes.

Params:
- `data`: Input bytes to hash.

Returns:
- Future that completes with a 32-byte `Uint8List` containing the SHA-256 digest.

Example:

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';

// Small helper to convert bytes to lower-case hex string
String toHex(Uint8List data) => data.map((b) => 
    b.toRadixString(16).padLeft(2, '0')).join();

Future<void> hashExample() async {
  // Hash a UTF-8 string
  final Uint8List input = Uint8List.fromList(utf8.encode('Hello PowerAuth'));
  final Uint8List digest = await PowerAuthCryptoUtils.hashSha256(input);

  // Display as hex and Base64
  print('SHA-256 (hex):   ${toHex(digest)}');
  print('SHA-256 (Base64): ${base64Encode(digest)}');
}
```

Notes

- Randomness comes from secure OS providers through native PowerAuthCore.
- The SHA-256 output is always exactly 32 bytes.
- Both utilities are asynchronous as they call into native code via a method channel.
