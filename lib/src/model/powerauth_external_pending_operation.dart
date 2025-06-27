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

/// ### iOS specific
/// 
/// The `PowerAuthExternalPendingOperationType` defines types of operation
/// started in another application that share activation data.
enum PowerAuthExternalPendingOperationType {
  activation,
  protocolUpgrade,
}

/// ### iOS specific
/// 
/// The `PowerAuthExternalPendingOperation` interface contains data that can identify an external
/// application that started the critical operation.
class PowerAuthExternalPendingOperation {
    /// Type of operation running in another application.
    PowerAuthExternalPendingOperationType externalOperationType;
    /// Identifier of external application that started the operation. This is the same identifier
    /// you provided to `PowerAuthSharingConfiguration` during the PowerAuth initialization.
    String externalApplicationId;

    PowerAuthExternalPendingOperation._({
      required this.externalOperationType,
      required this.externalApplicationId,
    });

    factory PowerAuthExternalPendingOperation.fromMap(Map map) {
      return PowerAuthExternalPendingOperation._(
        externalOperationType: PowerAuthExternalPendingOperationType.values.firstWhere(
          (e) => e.toString().split('.').last == map['externalOperationType'],
          orElse: () => PowerAuthExternalPendingOperationType.activation,
        ),
        externalApplicationId: map['externalApplicationId'] as String,
      );
    }
}