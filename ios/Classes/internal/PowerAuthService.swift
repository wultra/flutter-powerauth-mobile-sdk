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

internal class PowerAuthService: PowerAuthFlutterService {
    
    var name: String { "PowerAuth" }
    private let register: PowerAuthObjectRegister
    
    init(register: PowerAuthObjectRegister) {
        self.register = register
    }
    
    let handlers = [
        "configure": configure,
        "isConfigured": isConfigured,
        "deconfigure": deconfigure,
        "hasValidActivation": hasValidActivation,
        "canStartActivation": canStartActivation,
        "hasPendingActivation": hasPendingActivation,
        "getActivationIdentifier": getActivationIdentifier,
        "getActivationFingerprint": getActivationFingerprint,
        "fetchActivationStatus": fetchActivationStatus,
        "removeActivationLocal": removeActivationLocal,
        "removeActivationWithAuthentication": removeActivationWithAuthentication,
        "createActivation": createActivation,
        "persistActivation": persistActivation,
        "validatePassword": validatePassword,
        "changePassword": changePassword,
        "requestGetSignature": requestGetSignature,
        "requestSignature": requestSignature,
        "offlineSignature": offlineSignature,
        "verifyServerSignedData": verifyServerSignedData,
        "getBiometryInfo": getBiometryInfo,
        "addBiometryFactor": addBiometryFactor,
        "hasBiometryFactor": hasBiometryFactor,
        "removeBiometryFactor": removeBiometryFactor,
        "authenticateWithBiometry": authenticateWithBiometry
    ]
    
    // Possible Flutter call parameters
    enum Args: String {
        case instanceId
        case configuration
        case activation
        case authentication
        case password
        case oldPassword
        case newPassword
        case uriId
        case queryParams
        case method
        case body
        case nonce
        case data
        case signature
        case useMasterKey
        case prompt
    }
    
    private var biometricKeyCache = [String: (data: PowerAuthData, created: Date)]()
    
    private func isConfigured(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        let instanceId: String = try call.requireParameter(.instanceId)
        let sdk: PowerAuthSDK? = register.find(id: instanceId)
        result(sdk != nil)
    }
    
    private func configure(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        
        let instanceId: String = try call.requireParameter(.instanceId)
        
        let configuration: FlutterMap = try call.requireParameter(.configuration)
        
        guard let paConfig = PowerAuthConfiguration(instanceId: instanceId, arguments: configuration) else {
            throw PluginException(.wrongParameter, message: "Invalid PowerAuthConfiguration parameters.")
        }
        
        guard let sdk = PowerAuthSDK(configuration: paConfig) else {
            throw PluginException(.wrongParameter, message: "Invalid PowerAuthConfiguration - could not create PowerAuthSDK object.")
        }
        
        let registered = register.add(id: instanceId, tag: instanceId, policies: [.manual()]) {
            sdk
        }
        if registered {
            result(true)
        } else {
            throw PluginException(.flutterError, message: "PowerAuth instance is alread configured.")
        }
    }
    
    private func deconfigure(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        let instanceId: String = try call.requireParameter(.instanceId)
        register.remove(id: instanceId)
        result(true)
    }
    
    private func hasValidActivation(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, _ in
            result(sdk.hasValidActivation())
        }
    }
    
    private func canStartActivation(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, _ in
            result(sdk.canStartActivation())
        }
    }
    
    private func hasPendingActivation(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, _ in
            result(sdk.hasPendingActivation())
        }
    }
    
    private func getActivationIdentifier(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, _ in
            result(sdk.activationIdentifier)
        }
    }
    
    private func getActivationFingerprint(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, _ in
            result(sdk.activationFingerprint)
        }
    }
    
    private func fetchActivationStatus(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            
            sdk.fetchActivationStatus { status, error in
                
                wrap {
                    if let error {
                        throw error
                    }
                    let response: [String: Any?] = [
                        "state": status!.state.serializable,
                        "failCount": status!.failCount,
                        "maxFailCount": status!.maxFailCount,
                        "remainingAttempts": status!.remainingAttempts,
                        "customObject": status!.customObject
                    ]
                    
                    result(response)
                }
            }
        }
    }
    
    private func removeActivationLocal(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, _ in
            sdk.removeActivationLocal()
            result(nil)
        }
    }
    
    private func removeActivationWithAuthentication(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            
            sdk.removeActivation(with: try constructAuthentication(call)) { error in
                wrap {
                    if let error {
                        throw error
                    } else {
                        result(nil)
                    }
                }
            }
        }
    }
    
    private func createActivation(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            
            var paActivation: PowerAuthActivation?
            let activation: FlutterMap = try call.requireParameter(.activation)
            let name = activation["activationName"] as? String
            
            if let activationCode = activation["activationCode"] as? String {
                do {
                    paActivation = try PowerAuthActivation(activationCode: activationCode, name: name)
                } catch let e {
                    throw PluginException(.invalidActivationObject, message: "Invalid activation code provided", details: e.localizedDescription)
                }
            } else if let identityAttributes = activation["identityAttributes"] as? [String: String] {
                do {
                    paActivation = try PowerAuthActivation(identityAttributes: identityAttributes, name:name)
                } catch let e {
                    throw PluginException(.invalidActivationObject, message: "Invalid identity attributes provided", details: e.localizedDescription)
                }
            }
            
            guard let paActivation else {
                throw PluginException(.invalidActivationObject, message: "Activation object is invalid.", details: nil)
            }
            
            if let extras = activation["extras"] as? String {
                paActivation.with(extras: extras)
            }
            
            if let customAttributes = activation["customAttributes"] as? FlutterMap {
                paActivation.with(customAttributes: customAttributes)
            }
            
            if let otp = activation["additionalActivationOtp"] as? String {
                paActivation.with(additionalActivationOtp: otp)
            }
            
            sdk.createActivation(paActivation) { activationResult, error in
                
                wrap {
                    if let error {
                        throw error
                    }
                    
                    result([
                        "activationFingerprint": activationResult!.activationFingerprint,
                        "customAttributes": activationResult!.customAttributes
                    ])
                }
            }
        }
    }
    
    func persistActivation(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, _ in
            
            let auth = try constructAuthentication(call)
            try sdk.persistActivation(with: auth)
            result(nil)
        }
    }
    
    func validatePassword(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        
        try usePowerAuth(call, result) { sdk, wrap in
            
            let passParam: FlutterMap = try call.requireParameter(.password)
            let password = try self.usePassword(passParam)
            
            sdk.validatePassword(password: password) { error in
                wrap {
                    if let error {
                        throw error
                    }
                    result(nil)
                }
            }
        }
    }
    
    func changePassword(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        
        try usePowerAuth(call, result) { sdk, wrap in
            
            let oldPassParam: FlutterMap = try call.requireParameter(.oldPassword)
            let newPassParam: FlutterMap = try call.requireParameter(.newPassword)
            let oldPassword = try self.usePassword(oldPassParam)
            let newPassword = try self.usePassword(newPassParam)
            
            sdk.changePassword(from: oldPassword, to: newPassword) { error in
                wrap {
                    if let error {
                        throw error
                    }
                    result(nil)
                }
            }
        }
    }
    
    private func offlineSignature(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, _ in
            
            let auth = try constructAuthentication(call)
            let uriId: String = try call.requireParameter(.uriId)
            let nonce: String = try call.requireParameter(.nonce)
            let bodyString: String? = call.getParameter(.body)
            let data = bodyString?.data(using: .utf8)
            
            result(try sdk.offlineSignature(with: auth, uriId: uriId, body: data, nonce: nonce))
        }
    }
    
    private func verifyServerSignedData(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, _ in
            
            let stringData: String = try call.requireParameter(.data)
            let signature: String = try call.requireParameter(.signature)
            let masterKey: Bool = call.getParameter(.useMasterKey) ?? false
            
            guard let data = stringData.data(using: .utf8) else {
                // TODO: consider returning an error?
                result(false)
                return
            }
            
            let verifyResult = sdk.verifyServerSignedData(data, signature: signature, masterKey: masterKey)
            result(verifyResult)
            
        }
    }
    
    private func requestGetSignature(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, _ in
            
            let auth = try constructAuthentication(call)
            let uriId: String = try call.requireParameter(.uriId)
            let queryparams: [String: String]? = call.getParameter(.queryParams)
            
            let signature = try sdk.requestGetSignature(with: auth, uriId: uriId, params: queryparams)
            result([
                "key": signature.key,
                "value": signature.value
            ])
        }
    }
    
    private func requestSignature(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            
            let auth = try constructAuthentication(call)
            let uriId: String = try call.requireParameter(.uriId)
            let method: String = try call.requireParameter(.method)
            
            let bodyString: String? = call.getParameter(.body)
            let data = bodyString?.data(using: .utf8)
            
            let signature = try sdk.requestSignature(with: auth, method: method, uriId: uriId, body: data)
            result([
                "key": signature.key,
                "value": signature.value
            ])
        }
    }
    
    private func getBiometryInfo(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        let biometryType = switch PowerAuthKeychain.biometricAuthenticationInfo.biometryType {
        case .touchID: "fingerprint"
        case .faceID: "face"
        default: "none"
        }
        let canAuthenticate = switch PowerAuthKeychain.biometricAuthenticationInfo.currentStatus {
        case .available: "ok"
        case .notEnrolled: "notEnrolled"
        case .notAvailable: "notAvailable"
        case .notSupported: "notSupported"
        case .lockout: "lockout"
        default: "notAvailable" // fallback for Swift 6
        }
        
        result([
            "isAvailable": PowerAuthKeychain.canUseBiometricAuthentication,
            "biometryType": biometryType,
            "canAuthenticate": canAuthenticate
        ]);
    }
    
    private func addBiometryFactor(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            // Workaround for native SDK. We're expectint MISSING or PEDNING_ACTIVATION
            // but native SDK prioritize biometry-related error in this situation.
            guard sdk.hasValidActivation() else {
                throw PluginException(.missingActivation)
            }
            guard !sdk.hasPendingActivation() else {
                throw PluginException(.pendingActivation)
            }
            let passParam: FlutterMap = try call.requireParameter(.password)
            let password = try self.usePassword(passParam)
            sdk.addBiometryFactor(password: password) { error in
                wrap {
                    if let error {
                        throw error
                    }
                    result(nil)
                }
            }
        }
    }
    
    private func hasBiometryFactor(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            result(sdk.hasBiometryFactor())
        }
    }
    
    private func removeBiometryFactor(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            wrap {
                if sdk.removeBiometryFactor() {
                    result(nil)
                } else {
                    if !sdk.hasBiometryFactor() {
                        throw PluginException(.biometryNotConfigured, message: "Biometry not configured in this PowerAuth instance")
                    } else {
                        throw PluginException(.flutterError, message: "Biometry not configured in this PowerAuth instance")
                    }
                }
            }
        }
    }
    
    private func authenticateWithBiometry(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            
            let prompt: FlutterMap = try call.requireParameter(.prompt)
            
            guard let promptMessage = prompt["promptMessage"] as? String else {
                throw PluginException(.wrongParameter, message: "Missing 'promptMessage' in prompt parameter")
            }
            
            let cancelButton = prompt["cancelButtonTitle"] as? String
            let fallbackButton = prompt["fallbackButtonTitle"] as? String
            let context = LAContext()
            context.localizedReason = promptMessage
            context.localizedCancelTitle = cancelButton
            context.localizedFallbackTitle = fallbackButton ?? "" // empty string hides the button
            sdk.authenticateUsingBiometry(withContext: context) { authentication, error in
                wrap {
                    guard let authentication else {
                        throw error ?? PluginException(.unknownError, message: "Unknown error")
                    }
                    guard let overridenBiometryKey = authentication.overridenBiometryKey else {
                        throw PluginException(.unknownError, message: "Missing overridenBiometryKey in authentication")
                    }
                    // Allocate native object
                    let managedData = PowerAuthData(data: overridenBiometryKey, cleanup: true)
                    
                    // TODO: implement with object register -> see PA JS OBJC impl.
                    let keyId = UUID().uuidString
                    let timestamp = Date()
                    self.biometricKeyCache[keyId] = (managedData, timestamp)
                    result(keyId)
                }
            }
        }
    }
    
    // MARK: PowerAuth Helper methods
    
    private typealias WrapThrowBlock = (() throws -> Void) -> Void
    
    private func usePowerAuth(_ call: FlutterMethodCall, _ result: @escaping FlutterResult, _ block: (PowerAuthSDK, @escaping WrapThrowBlock) throws -> Void) throws {
        
        let instanceID: String = try call.requireParameter(.instanceId)
        
        guard let instance: PowerAuthSDK = register.find(id: instanceID) else {
            throw PluginException(.instanceNotConfigured, message: "PowerAuth instance not configured.")
        }
        
        let wrapBlock: WrapThrowBlock = { (tryBlock: () throws -> Void) in
            do {
                try tryBlock()
            } catch let e {
                result(FlutterError(thrownByPlugin: e))
            }
        }
        
        try block(instance, wrapBlock)
    }
    
    private func usePassword(_ dict: FlutterMap?) throws -> PowerAuthCorePassword {
        // TODO: we don't use object register yet, so just take plain password until implemented properly
        guard let dict, let password: String = dict.get(.password) else {
            throw PluginException(.wrongParameter, message: "Failed to parse provided password")
        }
        return PowerAuthCorePassword(string: password)
    }
    
    private func constructAuthentication(_ call: FlutterMethodCall) throws -> PowerAuthAuthentication {
        
        cleanupExpiredBiometricKeys()
        
        let dict: FlutterMap = try call.requireParameter(.authentication)
        let useBiometry = dict["isBiometry"] as? Bool ?? false // TODO: fallback ok?
        let persist = dict["isPersist"] as? Bool ?? false // TODO: fallback ok?
        
        let userPassword: FlutterMap? = dict.get(.password)
        
        if persist {
            // Activation persist
            let password = try usePassword(userPassword)
            if useBiometry {
                // All factors needs to be estabilished in activation.
                return PowerAuthAuthentication.persistWithPasswordAndBiometry(password: password)
            } else {
                return PowerAuthAuthentication.persistWithPassword(password: password)
            }
        } else {
            // Data signing
            if let userPassword {
                let password = try usePassword(userPassword)
                return PowerAuthAuthentication.possessionWithPassword(password: password)
            } else if useBiometry {
                if let biometryKeyId = dict["biometryKeyId"] as? String {
                    guard let entry = biometricKeyCache[biometryKeyId] else {
                        throw PluginException(.invalidNativeObject, message: "Biometric key in PowerAuthAuthentication object is no longer valid.")
                    }
                    biometricKeyCache.removeValue(forKey: biometryKeyId) // TODO: temp solution
                    return PowerAuthAuthentication.possessionWithBiometry(customBiometryKey: entry.data.data, customPossessionKey: nil)
                }
                let prompt = dict["biometricPrompt"] as? [String: String]
                let message = prompt?["promptMessage"]
                let title = prompt?["promptTitle"]
                if message != nil || title != nil {
                    let context = LAContext()
                    context.localizedReason = message ?? ""
                    context.localizedCancelTitle = title
                    return PowerAuthAuthentication.possessionWithBiometry(context: context)
                } else {
                    return PowerAuthAuthentication.possessionWithBiometry()
                }
            } else {
                return PowerAuthAuthentication.possession()
            }
        }
    }
    
    private func cleanupExpiredBiometricKeys() {
        let now = Date()
        
        biometricKeyCache.keys.forEach { key in
            let item = biometricKeyCache[key]!
            if (now.timeIntervalSince1970 - item.created.timeIntervalSince1970) >= CGFloat(Constants.BIOMETRY_KEY_KEEP_ALIVE_TIME) {
                biometricKeyCache.removeValue(forKey: key)
            }
        }
    }
}

private extension PowerAuthConfiguration {
    convenience init?(instanceId: String, arguments: FlutterMap) {
        guard
            let sdkConfig = arguments["configuration"] as? String,
            let baseEndpointUrl = arguments["baseEndpointUrl"] as? String
            else {
            return nil
        }
        
        self.init(instanceId: instanceId, baseEndpointUrl: baseEndpointUrl, configuration: sdkConfig)
    }
}

private extension PowerAuthActivationState {
    var serializable: String {
        return switch (self) {
        case .created: "created"
        case .pendingCommit: "pendingCommit"
        case .active: "active"
        case .blocked: "blocked"
        case .removed: "removed"
        case .deadlock: "deadlock"
        @unknown default: fatalError("UNSUPPORTED POWERAUTH ACTIVATION STATE")
        }
    }
}

private extension FlutterMap {
    func get<T>(_ key: PowerAuthService.Args) -> T? {
        return get(key.rawValue)
    }
}

private extension FlutterMethodCall {
    func requireParameter<T>(_ key: PowerAuthService.Args) throws -> T {
        return try requireParameter(key.rawValue)
    }
    
    func getParameter<T>(_ key: PowerAuthService.Args) -> T? {
        return getParameter(key.rawValue)
    }
}


// TODO: make sure this works properly
private class PowerAuthData {
    
    private(set) var data: Data
    private let cleanup: Bool
    
    init(data: Data, cleanup: Bool) {
        self.data = data
        self.cleanup = cleanup
    }
    
    deinit {
        if cleanup {
            let count = data.count
            _ = data.withUnsafeMutableBytes {
                $0.baseAddress?.initializeMemory(as: UInt8.self, repeating: 0, count: count)
            }
        }
    }
}
