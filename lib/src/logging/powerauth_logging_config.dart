/*
 * Copyright 2025 Wultra s.r.o.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/foundation.dart';
import 'powerauth_log_types.dart';

/// Configuration for PowerAuth SDK logging.
class PowerAuthLoggingConfig {
  const PowerAuthLoggingConfig({
    this.enabled = kDebugMode,
    this.level = PowerAuthLogLevel.info,
    this.logToConsole = true,
  });

  /// Whether logging is enabled.
  final bool enabled;

  /// Minimum log level to process.
  final PowerAuthLogLevel level;

  /// Whether logs should also be printed to the platform console.
  final bool logToConsole;

  /// Convenience helper that creates a copy of this config with the given fields replaced.
  PowerAuthLoggingConfig copyWith({
    bool? enabled,
    PowerAuthLogLevel? level,
    bool? logToConsole,
  }) => PowerAuthLoggingConfig(
    enabled: enabled ?? this.enabled,
    level: level ?? this.level,
    logToConsole: logToConsole ?? this.logToConsole,
  );

  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'level': level.name,
    'console': logToConsole,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PowerAuthLoggingConfig &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          level == other.level &&
          logToConsole == other.logToConsole;

  @override
  int get hashCode => Object.hash(enabled, level, logToConsole);

  @override
  String toString() =>
      'PowerAuthLoggingConfig(enabled: $enabled, level: $level, logToConsole: $logToConsole)';
}
