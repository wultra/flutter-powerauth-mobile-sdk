/*
 * Copyright 2025 Wultra s.r.o.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/suites/test_suite.dart';

class PowerAuthCryptoUtilsTests extends TestSuiteWithActivation {

  @override
  List<Future<void> Function()> getTests() => [testRandomBytes, testHashSha256];

  // Simple helper to convert bytes to lowercase hex string
  String _toHex(Uint8List data) {
    final sb = StringBuffer();
    for (final b in data) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }

  Future<void> testRandomBytes() async {
    // Generate random bytes of various lengths and validate properties
    final b16_a = await PowerAuthCryptoUtils.randomBytes(16);
    final b16_b = await PowerAuthCryptoUtils.randomBytes(16);
    final b32 = await PowerAuthCryptoUtils.randomBytes(32);

    // Length checks
    await expect(b16_a.length).toBe(16, message: 'randomBytes(16) should return 16 bytes');
    await expect(b16_b.length).toBe(16, message: 'randomBytes(16) should return 16 bytes');
    await expect(b32.length).toBe(32, message: 'randomBytes(32) should return 32 bytes');

    // Content should not be all zeros (very strong indication of proper randomness)
    final hasNonZero16 = b16_a.any((e) => e != 0);
    final hasNonZero32 = b32.any((e) => e != 0);
    await expect(hasNonZero16).toBe(true, message: 'randomBytes(16) should not be all zeros');
    await expect(hasNonZero32).toBe(true, message: 'randomBytes(32) should not be all zeros');

    // Two consecutive calls should yield different byte sequences with overwhelming probability
    // Compare by content (base64) to avoid identity-based comparison
    await expect(base64.encode(b16_a)).notToBe(base64.encode(b16_b), message: 'Two random sequences should differ');

    // Different lengths should obviously produce different results length-wise
    await expect(b16_a.length).notToBe(b32.length, message: 'Different lengths must differ');
  }

  Future<void> testHashSha256() async {
    // Test vectors from FIPS 180-4 / NIST
    // 1) Empty string
    final empty = Uint8List(0);
    final emptyHash = await PowerAuthCryptoUtils.hashSha256(empty);
    await expect(_toHex(emptyHash)).toBe(
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      message: 'SHA-256("") must match known vector',
    );

    // 2) 'abc'
    final abcHash = await PowerAuthCryptoUtils.hashSha256(Uint8List.fromList(utf8.encode('abc')));
    await expect(_toHex(abcHash)).toBe(
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      message: 'SHA-256("abc") must match known vector',
    );

    // 3) Long message
    const msg = 'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq';
    final longHash = await PowerAuthCryptoUtils.hashSha256(Uint8List.fromList(utf8.encode(msg)));
    await expect(_toHex(longHash)).toBe(
      '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1',
      message: 'SHA-256(long message) must match known vector',
    );

    // Output length should always be 32 bytes
    final randomInput = Uint8List.fromList(List<int>.generate(50, (i) => i));
    final randomHash = await PowerAuthCryptoUtils.hashSha256(randomInput);
    await expect(randomHash.length).toBe(32, message: 'SHA-256 output is 32 bytes');

    // Determinism: hashing the same input twice yields the same result
    final repeatHash = await PowerAuthCryptoUtils.hashSha256(Uint8List.fromList(utf8.encode('abc')));
    await expect(base64.encode(abcHash)).toBe(base64.encode(repeatHash), message: 'SHA-256 should be deterministic');
  }
}