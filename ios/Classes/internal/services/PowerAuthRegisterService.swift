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

import PowerAuthCore
import Flutter

internal class PowerAuthRegisterService: PowerAuthFlutterService {
    
    typealias Service = PowerAuthRegisterService
    
    // MARK: - PowerAuthFlutterService members
    
    var name: String { "PowerAuthRegister" }
    private let register: PowerAuthObjectRegister
    
    init(register: PowerAuthObjectRegister) {
        self.register = register
    }
    
    let handlers = [
        "register_debugDump": debugDump,
        "register_debugCommand": debugCommand,
        "register_isValidNativeObject": isValidNativeObject
    ]
    
    fileprivate enum Args: String {
        case objectId
        case instanceId
        case command
        case data
    }
    
    private func isValidNativeObject(_ call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        let objectId: String = try call.requireParameter(Args.objectId)
        result(register.contains(id: objectId))
    }
    
    #if DEBUG
    private func debugDump(_ call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        let instanceId: String? = call.getParameter(Args.instanceId)
        result(register.debugDumpObjectsWithTag(tag: instanceId))
    }
    
    enum NativeObjectCmd: String {
        case create
        case release
        case releaseAll
        case use
        case find
        case touch
        case setPeriod
    }
    
    
    enum NativeObjectType: String {
        case data
        case secureData = "secure-data"
        case number
        case password
    }
    
    private func debugCommand(_ call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        let command: String = try call.requireParameter(Args.command)
        let options: FlutterMap = try call.requireParameter(Args.data)
        
        let objectId = options["objectId"] as? String
        let objectTag = options["objectTag"] as? String
        guard let ot = options["objectType"] as? String, let objectType = NativeObjectType(rawValue: ot) else {
            throw PluginException(.wrongParameter, message: "Unknown object type parameter")
        }
        
//        if objectType == .data || objectType == .secureData {
//            
//        }
        
        
//        Class objectClass = Nil;
//        if ([@"data" isEqual:objectType] || [@"secure-data" isEqual:objectType]) {
//            objectClass = [PowerAuthData class];
//        } else if ([@"number" isEqual:objectType]) {
//            objectClass = [NSNumber class];
//        } else if ([@"password" isEqual:objectType]) {
//            objectClass = [PowerAuthCoreMutablePassword class];
//        } else if ([@"encryptor" isEqual:objectType]) {
//            objectClass = [PowerAuthJsEncryptor class];
//        }
        
        if command == "create" {
            // The "create" command creates a new instance of managed object
            // and returns its ID to Flutter.
            
            // Prepare Release policy
            
            var policies = [ReleasePolicy]()
            (options["releasePolicy"] as? [String])?.forEach { policy in
                let components = policy.components(separatedBy: " ")
                let param = Int(components.last ?? "") ?? 1 // TODO: fallback OK?
                if policy == "manual" {
                    policies.append(.manual())
                } else if policy.starts(with: "afterUse") {
                    policies.append(.afterUse(param))
                } else if policy.starts(with: "keepAlive") {
                    policies.append(.keepAlive(param))
                } else if policy.starts(with: "expire") {
                    policies.append(.expire(param))
                }
            }
            
            if policies.count > 0 {
                // Create new object
                let instance: Any?
                switch objectType {
                case .data:
                    let td = "TEST-DATA".data(using: .utf8)!
                    instance = PowerAuthData(data: td, cleanup: false)
                case .secureData:
                    let td = "SECURE-DATA".data(using: .utf8)!
                    instance = PowerAuthData(data: td, cleanup: false)
                case .number:
                    instance = 42
                case .password:
                    instance = PowerAuthCoreMutablePassword()
                }
                if let instance {
                    let objectId = register.add(object: instance, tag: objectTag, policies: policies)
                    result(objectId)
                    return
                }
            }
        } else if command == "release" {
            // The "release" command release object with given identifier and returns true / false whether object was removed.
            if let objectId {
                // releaseAny allows to release any object
                result(register.removeAny(id: objectId) != nil)
                return
            }
        } else if command == "releaseAll" {
            // The "releaseAll" command release all objects with a specified tag. If tag is nil, then releases all objects
            // from the register.
            if let objectTag {
                register.removeAll(tag: objectTag)
            } else {
                register.removeAll()
            }
            result(nil)
            return
        } else if command == "use" {
            // The "use" command find object and mark it as used and returns true / false whether object was found.
            if let objectId {
                result(register.useAny(id: objectId) != nil);
                return
            }
        } else if command == "find" {
            // The "find" command just find the object in the register and returns true / false if object still exists.
            if let objectId {
                result(register.contains(id: objectId))
                return
            }
        } else if command == "touch" {
            // The "touch" command prolongs lifetime of object in the register and returns true / false if object still exists.
            if let objectId {
                result(register.touchAny(id: objectId))
                return
            }
        } else if command == "setPeriod" {
            // TODO: improve?
            if let period = options["cleanupPeriod"] as? Int {
                register.setCleanupPeriod(period)
            }
            result(nil);
            return
        }
        throw PluginException(.wrongParameter, message: "Wrong parameter for cmd \(command), \(options)")
    }
    #else
    
    private func debugDump(_ call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        result(nil)
    }
    
    private func debugCommand(_ call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        result(nil)
    }
    #endif
}
