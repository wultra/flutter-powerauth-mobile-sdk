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

/// Contains information about recovery code and PUK, created during the activation process.
class PowerAuthRecoveryActivationData {

  /// Contains recovery code.
  final String recoveryCode;

  /// Contains PUK, valid with recovery code.
  final String puk;

  PowerAuthRecoveryActivationData({
    required this.recoveryCode,
    required this.puk,
  });

  factory PowerAuthRecoveryActivationData.fromMap(Map<dynamic, dynamic> map) {
    return PowerAuthRecoveryActivationData(
      recoveryCode: map['recoveryCode'] as String,
      puk: map['puk'] as String,
    );
  }

  // TODO: do we ever want to send this with toMap() conversion?
}
