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
    private let logger = Logger(enableDebug: false)
    
    public override init() {
        
        let services: [any PowerAuthFlutterService] = [
            PowerAuthService(),
            PowerAuthUtilsService()
        ]
        
        var handlers = [String: (service: any PowerAuthFlutterService, handler: Any)]()
        
        services.forEach { service in
            service.opaqueHandlers.forEach { k, v in
                handlers[k] = (service, v)
            }
        }
        
        self.handlers = handlers
        
        super.init()
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "powerauth_plugin", binaryMessenger: registrar.messenger())
        let instance = PowerAuthPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        guard let (service, handler) = handlers[call.method] else {
            defaultHandle(call, result)
            return
        }
        
        do {
            logger.debug("Call \(call.method) being handeled by the \(service.name) service")
            try service.handle(handler, call, result)
        } catch let e {
            result(FlutterError(thrownByPlugin: e))
        }
    }
    
    private func defaultHandle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        if call.method == "getPlatformVersion" {
            result("iOS " + UIDevice.current.systemVersion)
        } else {
            logger.info("PowerAuth plugin received unexpected method: \(call.method)")
            result(FlutterMethodNotImplemented)
        }
    }
}

private extension PowerAuthFlutterService {
    func handle(_ handler: Any, _ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try (handler as! Handler)(self)(call, result)
    }
    
    var opaqueHandlers: [String: Any] {
        return handlers.mapValues { $0 }
    }
}

private class Logger {
    
    private let enableDebug: Bool
    
    init(enableDebug: Bool = false) {
        self.enableDebug = enableDebug
    }
    
    func debug(_ message: String) {
        if enableDebug {
            print("PowerAuthPlugin: \(message)")
        }
    }
    
    func info(_ message: String) {
        print("PowerAuthPlugin: \(message)")
    }
}
