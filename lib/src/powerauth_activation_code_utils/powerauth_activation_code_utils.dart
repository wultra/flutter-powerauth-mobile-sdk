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

import 'dart:async';

import 'powerauth_activation_code_utils_platform_interface.dart';
import '../model/powerauth_activation_code.dart';

/// Provides utility functions related to PowerAuth activation codes nd PIN strength.
/// The `PowerAuthActivationCodeUtil` provides various set of methods for parsing and validating
/// activation codes.
///
/// Current format:
/// ```
/// code without signature:    CCCCC-CCCCC-CCCCC-CCCCC
/// code with signature:       CCCCC-CCCCC-CCCCC-CCCCC#BASE64_STRING_WITH_SIGNATURE
/// ```
/// 
/// - Where the 'C' is Base32 sequence of characters, fully decodable into the sequence of bytes.
///   The validator then compares CRC-16 checksum calculated for the first 10 bytes and compares
///   it to last two bytes (in big endian order).
/// 
/// - Where the 'D' is digit (0 - 9)
class PowerAuthActivationCodeUtil {

  PowerAuthActivationCodeUtil._();

  static PowerAuthUtilsPlatform get _platform => PowerAuthUtilsPlatform.instance;

  /// Parses an activation code string (e.g., "ABCDE-FGHIJ-KLMNO-PQRST#signature").
  /// Returns a [PowerAuthActivationCode] object containing the code and optional signature.
  /// Throws an exception if the format is invalid.
  static Future<PowerAuthActivationCode> parseActivationCode(String activationCode,) => _platform.parseActivationCode(activationCode);

  /// Validates the format of an activation code (must not contain the signature part).
  static Future<bool> validateActivationCode(String activationCode) => _platform.validateActivationCode(activationCode);

  /// Checks if a character (given as Unicode code point) is a valid character
  /// for activation codes (Base32: A-Z, 2-7).
  static Future<bool> validateTypedCharacter(int character) => _platform.validateTypedCharacter(character);

  /// Validates and potentially corrects a typed character (Unicode code point)
  /// for activation codes.
  ///
  /// Corrections performed:
  /// - Lowercase to uppercase (a -> A)
  /// - '0' to 'O'
  /// - '1' to 'I'
  ///
  /// Returns the corrected character code point.
  /// Throws if the character is invalid and cannot be corrected.
  static Future<int> correctTypedCharacter(int character) => _platform.correctTypedCharacter(character);

  // TODO: implement!
  /// Tests the strength of a numeric PIN.
  ///
  /// Accepts a [String] or [PowerAuthPassword] containing only digits.
  ///
  /// Throws a [PowerAuthException] with [PowerAuthErrorCode.wrongParameter]
  /// if the PIN contains non-digit characters or its length is less than 4.
  ///
  /// Returns a [PinTestResult] indicating potential weaknesses.
  // static Future<PinTestResult> testPin(Object pin) => _platform.testPin(pin);
}
