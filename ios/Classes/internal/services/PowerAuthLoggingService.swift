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

import Foundation
import Flutter

internal class PowerAuthLoggingService: PowerAuthFlutterService {
    
    let name = "PowerAuthLogging"
    
    let handlers = [
        "logging_configure": configure
    ]
    
    // MARK: - Handlers
    
    private func configure(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let enabled = args["enabled"] as? Bool,
              let levelString = args["level"] as? String,
              let level = PowerAuthLogLevel(levelString: levelString) else {
            throw PluginException(.wrongParameter, message: "Enabled or level is missing in arguments.")
        }
        
        PowerAuthLogger.enabled = enabled
        PowerAuthLogger.level = level
        result(nil)
    }
}

private extension PowerAuthLogLevel {
    init?(levelString: String) {
        switch levelString.lowercased() {
        case "verbose":
            self = .verbose
        case "debug":
            self = .debug
        case "info":
            self = .info
        case "warning":
            self = .warning
        case "error":
            self = .error
        default:
            return nil
        }
    }
}
