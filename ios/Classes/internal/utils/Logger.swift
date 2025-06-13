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

import PowerAuth2
import Foundation

/**
 An enumeration of all possible logging levels used in the PowerAuth SDK.
 */
enum PowerAuthLogLevel: Int, Comparable {
    case verbose = 0
    case debug = 1
    case info = 2
    case warning = 3
    case error = 4
    
    static func < (lhs: PowerAuthLogLevel, rhs: PowerAuthLogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

/**
 A simple logger for internal SDK usage.
 */
class PowerAuthLogger {

    /// The current logging level.
    static var level: PowerAuthLogLevel = .info {
        didSet {
            updateNativeSdkLogging()
        }
    }

    /// Determines whether logging is enabled.
    static var enabled: Bool = true {
        didSet {
            updateNativeSdkLogging()
        }
    }

    /// Logs a verbose message.
    static func verbose(_ message: @autoclosure () -> String) {
        log(message, level: .verbose)
    }

    /// Logs a debug message.
    static func debug(_ message: @autoclosure () -> String) {
        log(message, level: .debug)
    }

    /// Logs an info message.
    static func info(_ message: @autoclosure () -> String) {
        log(message, level: .info)
    }

    /// Logs a warning message.
    static func warning(_ message: @autoclosure () -> String) {
        log(message, level: .warning)
    }

    /// Logs an error message.
    static func error(_ message: @autoclosure () -> String) {
        log(message, level: .error)
    }
    
    private static func updateNativeSdkLogging() {
        let shouldEnable = enabled && level.rawValue <= PowerAuthLogLevel.debug.rawValue
        let isVerbose = shouldEnable && level.rawValue == PowerAuthLogLevel.verbose.rawValue
        
        PowerAuthLogSetEnabled(shouldEnable)
        PowerAuthLogSetVerbose(isVerbose)
    }
    
    /// Central logging method.
    private static func log(_ message: () -> String, level: PowerAuthLogLevel) {
        guard enabled, self.level <= level else {
            return
        }
        
        // TODO: use the system Logger instead of printing?
        print("PowerAuthSDK: \(message())")
    }
} 
