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

import Flutter
import UIKit
import PowerAuth2
import PowerAuthCore

public class PowerAuthPlugin: NSObject, FlutterPlugin {
    
    private let handlers: [String: (service: any PowerAuthFlutterService, handler: Any)]
    private let logger = PowerAuthLogger()
    
    public override init() {
        // Notify the registry that a new plugin instance has been attached.
        PowerAuthServiceRegistry.onPluginAttached()
        
        // Reference the registry handlers map
        self.handlers = PowerAuthServiceRegistry.handlers
        
        super.init()
        
        // Set the delegate for native PowerAuth SDK logs
        PowerAuthLogSetDelegate(logger)
    }
    
    deinit {
        // Remove the delegate when the plugin is deallocated
        PowerAuthLogSetDelegate(nil)
        PowerAuthServiceRegistry.onPluginDetached()
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "powerauth_plugin", binaryMessenger: registrar.messenger())
        let instance = PowerAuthPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        let loggingChannel = FlutterEventChannel(name: "com.wultra.powerauth.flutter/logging", binaryMessenger: registrar.messenger())
        loggingChannel.setStreamHandler(instance.logger)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        guard let (service, handler) = handlers[call.method] else {
            defaultHandle(call, result)
            return
        }
        
        do {
            try service.handle(handler, call, result)
        } catch let e {
            PowerAuthLogger.error("PowerAuth plugin with method \(call.method) threw an error: \(e.localizedDescription)")
            result(FlutterError(thrownByPlugin: e))
        }
    }
    
    private func defaultHandle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        PowerAuthLogger.warning("PowerAuth plugin received unexpected method: \(call.method)")
        result(FlutterMethodNotImplemented)
    }
}

private extension PowerAuthFlutterService {
    func handle(_ handler: Any, _ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try (handler as! Handler)(self)(call, result)
    }
}
