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
import 'package:flutter_test/flutter_test.dart';

String _toHex(Uint8List data) =>
    data.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

void main() {
  group('Crypto utils tests', () {
    test('testRandomBytes', () async {
      // Typical lengths should return data of requested size and not all zeros
      final lengths = [1, 2, 3, 4, 5, 16, 32, 64, 127, 128, 1024];
      for (final len in lengths) {
        final data = await PowerAuthCryptoUtils.randomBytes(len);
        expect(data.length, len);
        final allZero = data.every((b) => b == 0);
        expect(allZero, false);
      }

      // Different calls should yield different sequences with very high probability
      final r1 = await PowerAuthCryptoUtils.randomBytes(32);
      final r2 = await PowerAuthCryptoUtils.randomBytes(32);
      expect(_toHex(r1), isNot(equals(_toHex(r2))));

      // Zero length should fail with WRONG_PARAMETER
      await expectLater(
        PowerAuthCryptoUtils.randomBytes(0),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            'code',
            PowerAuthErrorCode.wrongParameter,
          ),
        ),
      );

      // Negative length should fail with WRONG_PARAMETER
      await expectLater(
        PowerAuthCryptoUtils.randomBytes(-1),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            'code',
            PowerAuthErrorCode.wrongParameter,
          ),
        ),
      );
    });

    test('testHashSha256', () async {
      // 1) Empty string
      final empty = Uint8List(0);
      final emptyHash = await PowerAuthCryptoUtils.hashSha256(empty);
      expect(
        _toHex(emptyHash),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );

      // 2) 'wultra rocks'
      final wultraHash = await PowerAuthCryptoUtils.hashSha256(
        Uint8List.fromList(utf8.encode('wultra rocks')),
      );
      expect(
        _toHex(wultraHash),
        'fe114b675533c5f25c89fcb2c347a40d2faf4800abd0e7419d70cdf18e493e5a',
      );

      // 3) Long message
      const msg =
          'This is very long test message that is available for commercial purposes.';
      final longHash = await PowerAuthCryptoUtils.hashSha256(
        Uint8List.fromList(utf8.encode(msg)),
      );
      expect(
        _toHex(longHash),
        '71c3abbb2bc7a18db58763c2e338ac98df98557965a12ec2bcd45865dede927a',
      );

      // Output length should always be 32 bytes
      final randomInput = Uint8List.fromList(List<int>.generate(50, (i) => i));
      final randomHash = await PowerAuthCryptoUtils.hashSha256(randomInput);
      expect(randomHash.length, 32);

      // Determinism: hashing the same input twice yields the same result
      final repeatHash = await PowerAuthCryptoUtils.hashSha256(
        Uint8List.fromList(utf8.encode('wultra rocks')),
      );
      expect(base64.encode(wultraHash), base64.encode(repeatHash));
    });
  });
}
