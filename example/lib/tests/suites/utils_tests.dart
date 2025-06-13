import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/suites/test_suite.dart';

class UtilsTests extends TestSuite {

  @override
  List<Future<void> Function()> getTests() => [testActivationCodeValidation, testActivationCodeParser];

  Future<void> testActivationCodeValidation() async {
    final validCodes = [
      // nice codes
      "AAAAA-AAAAA-AAAAA-AAAAA",
      "MMMMM-MMMMM-MMMMM-MUTOA",
      "VVVVV-VVVVV-VVVVV-VTFVA",
      "55555-55555-55555-55YMA",
      // random codes
      "W65WE-3T7VI-7FBS2-A4OYA",
      "DD7P5-SY4RW-XHSNB-GO52A",
      "X3TS3-TI35Z-JZDNT-TRPFA",
      "HCPJX-U4QC4-7UISL-NJYMA",
      "XHGSM-KYQDT-URE34-UZGWQ",
      "45AWJ-BVACS-SBWHS-ABANA",
      "BUSES-ETYN2-5HTFE-NOV2Q",
      "ATQAZ-WJ7ZG-FWA7J-QFAJQ",
      "MXSYF-LLQJ7-PS6LF-E2FMQ",
      "ZKMVN-4IMFK-FLSYX-ARRGA",
      "NQHGX-LNM2S-EQ4NT-G3NAA"
    ];
    for (final code in validCodes) {
      await expect(PowerAuthActivationCodeUtil.validateActivationCode(code)).toBe(true);
    }
    final invalidCodes = [
      "",
      " ",
      "KLMNO-PQRST",
      "KLMNO-PQRST-UVWXY-Z234",
      "KLMNO-PQRST-UVWXY-Z2345 ",
      "KLMNO-PQRST-UVWXY-Z2345#",
      "67AAA-B0BCC-DDEEF-GGHHI",
      "67AAA-BB1CC-DDEEF-GGHHI",
      "67AAA-BBBC8-DDEEF-GGHHI",
      "67AAA-BBBCC-DDEEF-GGHH9",
      "67aAA-BBBCC-DDEEF-GGHHI",
      "6-AAA-BB1CC-DDEEF-GGHHI",
      "67AA#-BB1CC-DDEEF-GGHHI",
      "67AABCBB1CC-DDEEF-GGHHI",
      "67AAB-BB1CCEDDEEF-GGHHI",
      "67AAA-BBBCC-DDEEFZGGHHI",
      "CCCCC-CCCCC-CCCCC-CNUUQ#ABCD",
      "EEEEE-EEEEE-EEEEE-E2OXA#AB=="
    ];
    for (final code in invalidCodes) {
      await expect(PowerAuthActivationCodeUtil.validateActivationCode(code)).toBe(false);
    }
  }

  Future<void> testActivationCodeParser() async {
    var code = await PowerAuthActivationCodeUtil.parseActivationCode('BBBBB-BBBBB-BBBBB-BTA6Q');
    await expect(code.activationCode).toBe('BBBBB-BBBBB-BBBBB-BTA6Q');
    await expect(code.activationSignature).toBeNull();

    code = await PowerAuthActivationCodeUtil.parseActivationCode('CCCCC-CCCCC-CCCCC-CNUUQ#ABCD');
    await expect(code.activationCode).toBe('CCCCC-CCCCC-CCCCC-CNUUQ');
    await expect(code.activationSignature).toBe('ABCD');

    code = await PowerAuthActivationCodeUtil.parseActivationCode('DDDDD-DDDDD-DDDDD-D6UKA#ABC=');
    await expect(code.activationCode).toBe('DDDDD-DDDDD-DDDDD-D6UKA');
    await expect(code.activationSignature).toBe('ABC=');

    code = await PowerAuthActivationCodeUtil.parseActivationCode('EEEEE-EEEEE-EEEEE-E2OXA#AB==');
    await expect(code.activationCode).toBe('EEEEE-EEEEE-EEEEE-E2OXA');
    await expect(code.activationSignature).toBe('AB==');

    final invalidCodes = [
      "",
      "#",
      "#AB==",
      "KLMNO-PQRST",
      "EEEEE-EEEEE-EEEEE-E2OXA#",
      "OOOOO-OOOOO-OOOOO-OZH2Q#",
      "SSSSS-SSSSS-SSSSS-SX7IA#AB",
      "UUUUU-UUUUU-UUUUU-UAFLQ#AB#",
      "WWWWW-WWWWW-WWWWW-WNR7A#ABA=#",
      "XXXXX-XXXXX-XXXXX-X6RBQ#ABA-="
    ];
    for (final invalidCode in invalidCodes) {
      await expect(PowerAuthActivationCodeUtil.parseActivationCode(invalidCode)).toThrow(PowerAuthErrorCode.invalidActivationCode);
    }
  }

  // TODO: add tests for autocorrection
}