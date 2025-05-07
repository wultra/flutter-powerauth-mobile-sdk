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
import PowerAuth2
import PowerAuthCore

internal class PowerAuthPasswordService: PowerAuthFlutterService  {
    
    let name = "PowerAuthPasswordService"
    private let register: PowerAuthObjectRegister
    
    init(register: PowerAuthObjectRegister) {
        self.register = register
    }
    
    let handlers = [
        "password_initialize": initialize,
        "password_release": release,
        "password_clear": clear,
        "password_length": length,
        "password_isEqual": isEqual,
        "password_addCharacter": addCharacter,
        "password_insertCharacter": insertCharacter,
        "password_removeCharacter": removeCharacter,
        "password_removeLastCharacter": removeLastCharacter
    ]
    
    fileprivate enum Args: String {
        case destroyOnUse
        case powerAuthInstanceId // TODO: needed?
        case autoreleaseTime
        case objectId
        case otherObjectId
        case character
        case at
    }
    
    private func initialize(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        
        let destroyOnUse: Bool = try call.requireParameter(.destroyOnUse)
        let paInstanceId: String? = call.getParameter(.powerAuthInstanceId)
        let autoreleaseTime = call.getParameter(.autoreleaseTime) ?? 0
        
        // TODO: supported scenario? (is supported in JS, do we want it here?)
        if let paInstanceId, !register.contains(id: paInstanceId) {
            throw PluginException(.instanceNotConfigured, message: "PowerAuth instance is not configured")
        }
        
        let releaseTime = ReleasePolicy.getTimeInterval(value: autoreleaseTime, defaultValue: Constants.PASSWORD_KEY_KEEP_ALIVE_TIME)
        var policies = [ReleasePolicy.keepAlive(releaseTime)]
        if destroyOnUse {
            policies.append(.afterUse(1))
        }
        result(register.add(object: PowerAuthCoreMutablePassword(), tag: paInstanceId, policies: policies))
    }
    
    private func release(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        let objectId = try call.getObjectId()
        register.remove(id: objectId)
        result(nil)
    }
    
    private func clear(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        let objectId = try call.getObjectId()
        try withPassword(id: objectId) { password in
            password.clear()
            result(nil)
        }
    }
    
    private func length(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        let objectId = try call.getObjectId()
        try withPassword(id: objectId) { password in
            result(password.length())
        }
    }
    
    private func isEqual(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        let objectId = try call.getObjectId()
        let otherObjectId: String = try call.requireParameter(.otherObjectId)
        try withPassword(id: objectId) { password in
            try self.withPassword(id: otherObjectId) { otherPassword in
                result(password.isEqual(to: otherPassword))
            }
        }
    }
    
    private func addCharacter(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        let objectId = try call.getObjectId()
        let character: Int = try call.requireParameter(.character)
        try withPassword(id: objectId, character: character) { password, char in
            password.addCharacter(char)
            result(password.length())
        }
    }
    
    private func insertCharacter(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        let objectId = try call.getObjectId()
        let character: Int = try call.requireParameter(.character)
        let at: Int = try call.requireParameter(.at)
        
        try withPassword(id: objectId, character: character) { password, char in
            let position = UInt(at)
            if position >= 0 && position <= password.length() {
                password.insertCharacter(char, at: position)
                result(password.length())
            }
            throw PluginException(.wrongParameter, message: "Position is out of range")
        }
    }
    
    private func removeCharacter(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        let objectId = try call.getObjectId()
        let at: Int = try call.requireParameter(.at)
        
        try withPassword(id: objectId) { password in
            let position = UInt(at)
            if position >= 0 && position < password.length() {
                password.removeCharacter(at: position)
                result(password.length())
            }
            throw PluginException(.wrongParameter, message: "Position is out of range")
        }
    }
    
    private func removeLastCharacter(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        let objectId = try call.getObjectId()
        try withPassword(id: objectId) { password in
            password.removeLastCharacter()
            result(password.length())
        }
    }
    
    private func withPassword(id: String, action: (PowerAuthCoreMutablePassword) throws -> Void) throws {
        guard let password: PowerAuthCoreMutablePassword = register.touch(id: id) else {
            throw PluginException(.invalidNativeObject, message: "Password object is no longer valid")
        }
        try action(password)
    }
    
    private func withPassword(id: String, character: Int, action: (PowerAuthCoreMutablePassword, UInt32) throws -> Void) throws {
        let codePoint = UInt32(character)
        
        guard codePoint <= Constants.CODEPOINT_MAX else {
            throw PluginException(.wrongParameter, message: "CodePoint is too big")
        }
        
        guard let password: PowerAuthCoreMutablePassword = register.touch(id: id) else {
            throw PluginException(.invalidNativeObject, message: "Password object is no longer valid")
        }
        try action(password, codePoint)
    }
}

private extension FlutterMap {
    func get<T>(_ key: PowerAuthPasswordService.Args) -> T? {
        return get(key.rawValue)
    }
}

private extension FlutterMethodCall {
    
    func getObjectId() throws -> String {
        return try requireParameter(.objectId)
    }
    
    func requireParameter<T>(_ key: PowerAuthPasswordService.Args) throws -> T {
        return try requireParameter(key.rawValue)
    }
    
    func getParameter<T>(_ key: PowerAuthPasswordService.Args) -> T? {
        return getParameter(key.rawValue)
    }
}
