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

/// Contains parsed components from a user-provided activation or recovery code.
class PowerAuthActivationCode {

  /// If created from an activation code, contains the code without the signature part.
  /// If created from a recovery code, contains the code without the optional "R:" prefix.
  final String activationCode;

  /// Signature calculated from [activationCode].
  /// Typically optional if the user typed the code manually.
  /// Always empty if created from a recovery code.
  final String? activationSignature;

  PowerAuthActivationCode({
    required this.activationCode,
    this.activationSignature,
  });

  factory PowerAuthActivationCode.fromMap(Map<dynamic, dynamic> map) {
    return PowerAuthActivationCode(
      activationCode: map['activationCode'] as String,
      // Handle potential null from native if signature isn't present
      activationSignature: map['activationSignature'] as String?,
    );
  }
}
