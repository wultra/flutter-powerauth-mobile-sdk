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

import '../debug/powerauth_debug.dart';
import 'powerauth_log_types.dart';

/// A simple Logger class.
class PowerAuthLogger {
  static void _log({
    required PowerAuthLogLevel level,
    required String message,
    String? tag,
  }) {
    if (PowerAuthDebug.loggingEnabled &&
        level.index >= PowerAuthDebug.logLevel.index) {
      final prefix = _logPrefix(level);

      // Optionally print to the Dart console
      if (PowerAuthDebug.logToConsole) {
        debugPrint("$prefix/${tag ?? 'SDK'}: $message");
      }

      // Forward the log the the public log stream
      PowerAuthDebug.pushLog(PowerAuthLog(level, message, tag: tag));
    }
  }

  /// Logs a verbose message.
  static void verbose(String message, {String? tag}) {
    _log(level: PowerAuthLogLevel.verbose, message: message, tag: tag);
  }

  /// Logs a debug message.
  static void debug(String message, {String? tag}) {
    _log(level: PowerAuthLogLevel.debug, message: message, tag: tag);
  }

  /// Logs an info message.
  static void info(String message, {String? tag}) {
    _log(level: PowerAuthLogLevel.info, message: message, tag: tag);
  }

  /// Logs a warning message.
  static void warning(String message, {String? tag}) {
    _log(level: PowerAuthLogLevel.warning, message: message, tag: tag);
  }

  /// Logs an error message.
  static void error(String message, {String? tag}) {
    _log(level: PowerAuthLogLevel.error, message: message, tag: tag);
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
