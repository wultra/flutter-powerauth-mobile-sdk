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

/// Result of a successful PowerAuth protocol upgrade.
class PowerAuthProtocolUpgradeResult {

  /// Indicates whether [PowerAuth.fetchActivationStatus] must be called to
  /// finish the protocol upgrade.
  final bool activationStatusFetchRequired;

  /// Decimalized activation fingerprint.
  ///
  /// The value is `null` while an activation status fetch is still required.
  final String? activationFingerprint;

  /// Indicates whether the biometry factor was removed during the upgrade.
  ///
  /// This value is available only on Android and is always `false` on iOS.
  /// If `true`, consider adding the biometry factor again after the protocol
  /// upgrade is fully finished.
  final bool biometryFactorRemoved;

  PowerAuthProtocolUpgradeResult({
    required this.activationStatusFetchRequired,
    required this.activationFingerprint,
    required this.biometryFactorRemoved,
  });

  factory PowerAuthProtocolUpgradeResult.fromMap(Map<dynamic, dynamic> map) {
    return PowerAuthProtocolUpgradeResult(
      activationStatusFetchRequired: map['activationStatusFetchRequired'] as bool,
      activationFingerprint: map['activationFingerprint'] as String?,
      biometryFactorRemoved: map['biometryFactorRemoved'] as bool,
    );
  }
}
