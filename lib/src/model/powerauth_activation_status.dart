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

import 'powerauth_activation_state.dart';
import '../logging/powerauth_logger.dart';

/// Represents the complete status of the activation.
class PowerAuthActivationStatus {

  /// State of the activation.
  final PowerAuthActivationState state;

  /// Number of failed authentication attempts in a row.
  final int failCount;

  /// Maximum number of allowed failed authentication attempts in a row.
  final int maxFailCount;

  /// Contains `(maxFailCount - failCount)` if state is `ACTIVE`, otherwise 0.
  final int remainingAttempts;

  /// Contains custom object returned from the server. The value is optional
  /// and PowerAuth Application Server must support this custom object.
  final Map<String, dynamic>? customObject;

  PowerAuthActivationStatus({
    required this.state,
    required this.failCount,
    required this.maxFailCount,
    required this.remainingAttempts,
    this.customObject,
  });

  factory PowerAuthActivationStatus.fromJson(Map<dynamic, dynamic> map) {

    PowerAuthActivationState parseState(String? stateString) {
      if (stateString == null) {
        return PowerAuthActivationState.removed;
      }
        
      try {
        return PowerAuthActivationState.values.firstWhere((e) => e.name == stateString);
      } catch (e) {
        
        PowerAuthLogger.warning("Unknown PowerAuthActivationState received: $stateString");
        return PowerAuthActivationState.removed;
      }
    }

    return PowerAuthActivationStatus(
      state: parseState(map['state'] as String?),
      failCount: map['failCount'] as int,
      maxFailCount: map['maxFailCount'] as int,
      remainingAttempts: map['remainingAttempts'] as int,
      customObject:
          map['customObject'] != null
              ? Map<String, dynamic>.from(map['customObject'] as Map)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    var json = {
      'state': state.name,
      'failCount': failCount,
      'maxFailCount': maxFailCount,
      'remainingAttempts': remainingAttempts,
      'customObject': customObject,
    };
    json.removeWhere((key, value) => value == null);
    return json;
  }
}
