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

/// Public log levels emitted by the PowerAuth SDK.
enum PowerAuthLogLevel {
  /// Log everything.
  verbose,

  /// Log debug messages.
  debug,

  /// Log informational messages.
  info,

  /// Log warnings.
  warning,

  /// Log errors.
  error,
}

/// A single log entry produced by the PowerAuth SDK.
class PowerAuthLog {
  PowerAuthLog(this.level, this.message, {this.tag, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  /// Severity of the log entry.
  final PowerAuthLogLevel level;

  /// Human-readable log text.
  final String message;

  /// Optional tag identifying the log origin (e.g. `PowerAuthNativeSDK`).
  final String? tag;

  /// When this log entry was created.
  final DateTime timestamp;
}
