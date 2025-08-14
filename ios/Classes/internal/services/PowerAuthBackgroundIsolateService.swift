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
import UIKit

internal class PowerAuthBackgroundIsolateService: PowerAuthFlutterService {
    
    let name = "isolate"
    
    private var backgroundFlutterEngine: FlutterEngine?
    
    let handlers = [
        "isolate_startBackgroundIsolate": startBackgroundIsolate,
        "isolate_removeBackgroundIsolate": removeBackgroundIsolate
    ]
    
    // MARK: - Handlers
    
    private func startBackgroundIsolate(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        guard backgroundFlutterEngine == nil else {
            PowerAuthLogger.debug("The background isolate is already running")
            result(nil)

            return
        }

        // Create a new Flutter engine for background isolate
        backgroundFlutterEngine = FlutterEngine(name: "background_isolate")
        
        // Start the engine
        backgroundFlutterEngine?.run()
        
        PowerAuthLogger.debug("Background isolate started successfully")
        result(nil)
    }
    
    private func removeBackgroundIsolate(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        clearFlutterEngine()
        result(nil)
    }
    
    // MARK: - Private methods
    
    private func clearFlutterEngine() {
        backgroundFlutterEngine?.destroyContext()
        backgroundFlutterEngine = nil
        PowerAuthLogger.debug("Background isolate removed")
    }
} 
