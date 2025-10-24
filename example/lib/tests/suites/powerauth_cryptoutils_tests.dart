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
  String _toHex(Uint8List data) =>
    data.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  Future<void> testRandomBytes() async {
    // 1) Typical lengths should return data of requested size and not all zeros
    final lengths = [1, 2, 3, 4, 5, 16, 32, 64, 127, 128, 1024];
    for (final len in lengths) {
      final data = await PowerAuthCryptoUtils.randomBytes(len);
      await expect(data.length).toBe(len, message: "Random bytes length must match request ($len)");
      final allZero = data.every((b) => b == 0);
      await expect(allZero).toBe(false, message: "Random bytes should not be all zeros (len=$len)");
    }

    // 2) Different calls should yield different sequences with very high probability
    // Use sufficiently large length to minimize collision probability.
    final r1 = await PowerAuthCryptoUtils.randomBytes(32);
    final r2 = await PowerAuthCryptoUtils.randomBytes(32);
    await expect(_toHex(r1)).notToBe(_toHex(r2), message: "Two random draws should differ");

    // 3) Zero length should fail with WRONG_PARAMETER
    await expect(PowerAuthCryptoUtils.randomBytes(0)).toThrow(PowerAuthErrorCode.wrongParameter,
        message: "Length must be positive number");

    // 4) Negative length should fail with WRONG_PARAMETER
    await expect(PowerAuthCryptoUtils.randomBytes(-1)).toThrow(PowerAuthErrorCode.wrongParameter,
        message: "Length must be positive number");
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

    // 2) 'wultra rocks'
    final wultraHash = await PowerAuthCryptoUtils.hashSha256(Uint8List.fromList(utf8.encode('wultra rocks')));
    await expect(_toHex(wultraHash)).toBe(
      'fe114b675533c5f25c89fcb2c347a40d2faf4800abd0e7419d70cdf18e493e5a',
      message: 'SHA-256("wultra rocks") must match known vector',
    );

    // 3) Long message
    const msg = 'This is very long test message that is available for commercial purposes.';
    final longHash = await PowerAuthCryptoUtils.hashSha256(Uint8List.fromList(utf8.encode(msg)));
    await expect(_toHex(longHash)).toBe(
      '71c3abbb2bc7a18db58763c2e338ac98df98557965a12ec2bcd45865dede927a',
      message: 'SHA-256(long message) must match known vector',
    );

    // Output length should always be 32 bytes
    final randomInput = Uint8List.fromList(List<int>.generate(50, (i) => i));
    final randomHash = await PowerAuthCryptoUtils.hashSha256(randomInput);
    await expect(randomHash.length).toBe(32, message: 'SHA-256 output is 32 bytes');

    // Determinism: hashing the same input twice yields the same result
    final repeatHash = await PowerAuthCryptoUtils.hashSha256(Uint8List.fromList(utf8.encode('wultra rocks')));
    await expect(base64.encode(wultraHash)).toBe(base64.encode(repeatHash), message: 'SHA-256 should be deterministic');
  }
}