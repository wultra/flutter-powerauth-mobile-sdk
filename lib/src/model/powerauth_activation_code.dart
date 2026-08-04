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

/// Contains parsed components from a user-provided activation.
class PowerAuthActivationCode {

  /// If created from an activation code, contains the code without the signature part.
  final String activationCode;

  /// Legacy signature suffix parsed from the input, if present.
  ///
  /// SDK 2.0 does not verify this value and the activation process ignores it.
  /// Use [activationCode] after parsing and stripping the suffix.
  final String? activationSignature;

  PowerAuthActivationCode({
    required this.activationCode,
    this.activationSignature,
  });

  factory PowerAuthActivationCode.fromMap(Map<dynamic, dynamic> map) {
    return PowerAuthActivationCode(
      activationCode: map['activationCode'] as String,
      activationSignature: map['activationSignature'] as String?,
    );
  }
}
