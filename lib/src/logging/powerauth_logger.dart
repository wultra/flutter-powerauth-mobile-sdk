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

import 'package:flutter/foundation.dart';

import '../powerauth/powerauth_platform_interface.dart';

/// An enumeration of all possible logging levels used in the PowerAuth SDK.
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

/// A simple logger for internal SDK usage.
class PowerAuthLogger {

  /// The current logging level.
  static PowerAuthLogLevel level = PowerAuthLogLevel.info;

  /// If true, then logger is enabled.
  static bool enabled = true;

  /// A private method channel instance to communicate with the native side.
  static final _platform = PowerAuthPlatform.instance;

  /// Enables or disables logging.
  ///
  /// The new value is also propagated to the underlying native PowerAuth SDKs.
  static Future<void> setEnabled(bool enabled) async {
    PowerAuthLogger.enabled = enabled;
    await _platform.setNativeLoggingEnabled(enabled);
  }

  /// Sets the minimum log level for the logger.
  ///
  /// The new level is also propagated to the underlying native PowerAuth SDKs.
  static Future<void> setLogLevel(PowerAuthLogLevel newLevel) async {
    level = newLevel;
    await _platform.setNativeLogLevel(newLevel);
  }

  /// Logs a verbose message.
  static void verbose(String Function() message) =>
      _log(PowerAuthLogLevel.verbose, message);

  /// Logs a debug message.
  static void debug(String Function() message) =>
      _log(PowerAuthLogLevel.debug, message);

  /// Logs an info message.
  static void info(String Function() message) =>
      _log(PowerAuthLogLevel.info, message);

  /// Logs a warning message.
  static void warning(String Function() message) =>
      _log(PowerAuthLogLevel.warning, message);

  /// Logs an error message.
  static void error(String Function() message) =>
      _log(PowerAuthLogLevel.error, message);

  /// Central logging method.
  static void _log(PowerAuthLogLevel messageLevel, String Function() message) {
    if (enabled && level.index <= messageLevel.index) {
      final prefix = _logPrefix(messageLevel);
      
      debugPrint("PowerAuthSDK: $prefix/ ${message()}");
    }
  }

  /// Returns a prefix for the log message.
  static String _logPrefix(PowerAuthLogLevel level) {
    switch (level) {
      case PowerAuthLogLevel.verbose:
        return "V";
      case PowerAuthLogLevel.debug:
        return "D";
      case PowerAuthLogLevel.info:
        return "I";
      case PowerAuthLogLevel.warning:
        return "W";
      case PowerAuthLogLevel.error:
        return "E";
    }
  }
}
