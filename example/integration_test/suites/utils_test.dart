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

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PowerAuthActivationCodeUtil – validateActivationCode', () {
    const validCodes = [
      // nice codes
      'AAAAA-AAAAA-AAAAA-AAAAA',
      'MMMMM-MMMMM-MMMMM-MUTOA',
      'VVVVV-VVVVV-VVVVV-VTFVA',
      '55555-55555-55555-55YMA',
      // random codes
      'W65WE-3T7VI-7FBS2-A4OYA',
      'DD7P5-SY4RW-XHSNB-GO52A',
      'X3TS3-TI35Z-JZDNT-TRPFA',
      'HCPJX-U4QC4-7UISL-NJYMA',
      'XHGSM-KYQDT-URE34-UZGWQ',
      '45AWJ-BVACS-SBWHS-ABANA',
      'BUSES-ETYN2-5HTFE-NOV2Q',
      'ATQAZ-WJ7ZG-FWA7J-QFAJQ',
      'MXSYF-LLQJ7-PS6LF-E2FMQ',
      'ZKMVN-4IMFK-FLSYX-ARRGA',
      'NQHGX-LNM2S-EQ4NT-G3NAA',
    ];

    for (final code in validCodes) {
      test('valid → $code', () async {
        expect(
          await PowerAuthActivationCodeUtil.validateActivationCode(code),
          isTrue,
        );
      });
    }

    const invalidCodes = [
      '',
      ' ',
      'KLMNO-PQRST',
      'KLMNO-PQRST-UVWXY-Z234',
      'KLMNO-PQRST-UVWXY-Z2345 ',
      'KLMNO-PQRST-UVWXY-Z2345#',
      '67AAA-B0BCC-DDEEF-GGHHI',
      '67AAA-BB1CC-DDEEF-GGHHI',
      '67AAA-BBBC8-DDEEF-GGHHI',
      '67AAA-BBBCC-DDEEF-GGHH9',
      '67aAA-BBBCC-DDEEF-GGHHI',
      '6-AAA-BB1CC-DDEEF-GGHHI',
      '67AA#-BB1CC-DDEEF-GGHHI',
      '67AABCBB1CC-DDEEF-GGHHI',
      '67AAB-BB1CCEDDEEF-GGHHI',
      '67AAA-BBBCC-DDEEFZGGHHI',
      'CCCCC-CCCCC-CCCCC-CNUUQ#ABCD',
      'EEEEE-EEEEE-EEEEE-E2OXA#AB==',
    ];

    for (final code in invalidCodes) {
      test('invalid → $code', () async {
        expect(
          await PowerAuthActivationCodeUtil.validateActivationCode(code),
          isFalse,
        );
      });
    }
  });

  group('PowerAuthActivationCodeUtil – parseActivationCode', () {
    test('code without signature', () async {
      final result = await PowerAuthActivationCodeUtil.parseActivationCode(
        'BBBBB-BBBBB-BBBBB-BTA6Q',
      );
      expect(result.activationCode, 'BBBBB-BBBBB-BBBBB-BTA6Q');
      expect(result.activationSignature, isNull);
    });

    test('code with short signature', () async {
      final result = await PowerAuthActivationCodeUtil.parseActivationCode(
        'CCCCC-CCCCC-CCCCC-CNUUQ#ABCD',
      );
      expect(result.activationCode, 'CCCCC-CCCCC-CCCCC-CNUUQ');
      expect(result.activationSignature, 'ABCD');
    });

    test('code with medium signature', () async {
      final result = await PowerAuthActivationCodeUtil.parseActivationCode(
        'DDDDD-DDDDD-DDDDD-D6UKA#ABC=',
      );
      expect(result.activationCode, 'DDDDD-DDDDD-DDDDD-D6UKA');
      expect(result.activationSignature, 'ABC=');
    });

    test('code with longest signature', () async {
      final result = await PowerAuthActivationCodeUtil.parseActivationCode(
        'EEEEE-EEEEE-EEEEE-E2OXA#AB==',
      );
      expect(result.activationCode, 'EEEEE-EEEEE-EEEEE-E2OXA');
      expect(result.activationSignature, 'AB==');
    });

    const invalidCodes = [
      '',
      '#',
      '#AB==',
      'KLMNO-PQRST',
      'EEEEE-EEEEE-EEEEE-E2OXA#',
      'OOOOO-OOOOO-OOOOO-OZH2Q#',
      'SSSSS-SSSSS-SSSSS-SX7IA#AB',
      'UUUUU-UUUUU-UUUUU-UAFLQ#AB#',
      'WWWWW-WWWWW-WWWWW-WNR7A#ABA=#',
      'XXXXX-XXXXX-XXXXX-X6RBQ#ABA-=',
    ];

    for (final code in invalidCodes) {
      test('invalid → $code', () async {
        await expectLater(
          PowerAuthActivationCodeUtil.parseActivationCode(code),
          throwsA(
            isA<PowerAuthException>().having(
              (e) => e.code,
              'code',
              PowerAuthErrorCode.invalidActivationCode,
            ),
          ),
        );
      });
    }
  });

  group('PowerAuthActivationCodeUtil – validateTypedCharacter', () {
    const validChars = ['A', 'Z', 'M', 'V', '2', '7'];
    for (final ch in validChars) {
      test('valid → $ch', () async {
        expect(
          await PowerAuthActivationCodeUtil.validateTypedCharacter(
            ch.codeUnitAt(0),
          ),
          isTrue,
        );
      });
    }

    const invalidChars = ['a', 'o', 'l', '0', '1', '8', '9', '#', ' '];
    for (final ch in invalidChars) {
      test('invalid → $ch', () async {
        expect(
          await PowerAuthActivationCodeUtil.validateTypedCharacter(
            ch.codeUnitAt(0),
          ),
          isFalse,
        );
      });
    }
  });

  group('PowerAuthActivationCodeUtil – correctTypedCharacter', () {
    const corrections = {
      'A': 'A',
      '2': '2',
      'a': 'A',
      'o': 'O',
      'l': 'L',
      'i': 'I',
      '0': 'O',
      '1': 'I',
    };

    corrections.forEach((input, expected) {
      test('correct → $input → $expected', () async {
        final result = await PowerAuthActivationCodeUtil.correctTypedCharacter(
          input.codeUnitAt(0),
        );
        expect(String.fromCharCode(result), expected);
      });
    });

    const nonCorrectable = ['8', '9', '#', ' '];
    for (final ch in nonCorrectable) {
      test('non-correctable → $ch', () async {
        try {
          final result =
              await PowerAuthActivationCodeUtil.correctTypedCharacter(
                ch.codeUnitAt(0),
              );
          // iOS returns 0 for invalid characters that cannot be corrected
          expect(result, 0);
        } catch (e) {
          expect(
            e,
            isA<PowerAuthException>().having(
              (e) => e.code,
              'code',
              PowerAuthErrorCode.invalidCharacter,
            ),
          );
        }
      });
    }
  });
}
