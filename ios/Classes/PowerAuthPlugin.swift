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
    
    // MARK: - FLUTTER PLUGIN HANDLING
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "powerauth_plugin", binaryMessenger: registrar.messenger())
        let instance = PowerAuthPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        // Similarly to Android - sub-plugin registration to autolinking..
        PowerAuthPasswordPlugin.register(with: registrar)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        do {
            switch call.method {
            case "configure": try configure(call, result)
            case "isConfigured": try isConfigured(call, result)
            case "deconfigure": try deconfigure(call, result)
            case "hasValidActivation": try hasValidActivation(call, result)
            case "canStartActivation": try canStartActivation(call, result)
            case "hasPendingActivation": try hasPendingActivation(call, result)
            case "getActivationIdentifier": try getActivationIdentifier(call, result)
            case "getActivationFingerprint": try getActivationFingerprint(call, result)
            case "fetchActivationStatus": try fetchActivationStatus(call, result)
            case "removeActivationLocal": try removeActivationLocal(call, result)
            case "removeActivationWithAuthentication": try removeActivationWithAuthentication(call, result)
                // "getExternalPendingOperation" -> getExternalPendingOperation(instanceId, result)
            case "createActivation": try createActivation(call, result)
            case "persistActivation": try persistActivation(call, result)
            case "validatePassword": try validatePassword(call, result)
            case "changePassword": try changePassword(call, result)
                // "requestGetSignature" -> requestGetSignature(call, instanceId, result)
                // "requestSignature" -> requestSignature(call, instanceId, result)
            case "offlineSignature": try offlineSignature(call, result)
            case "verifyServerSignedData": try verifyServerSignedData(call, result)
            case "getPlatformVersion": result("iOS " + UIDevice.current.systemVersion)
                
            default:
                print("PowerAuthPlugin received unexpected method: \(call.method)")
                result(FlutterMethodNotImplemented)
            }
        } catch let e {
            result(FlutterError(thrownByPlugin: e))
        }
    }
    
    enum ArgKeys: String {
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
    }
    
    // MARK: - POWERAUTH PLUGIN API CODE
    
    private var instances = [String: PowerAuthSDK]()
    
    private func isConfigured(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        let instanceId: String = try call.requireParameter(.instanceId)
        result(instances[instanceId] != nil)
    }
    
    private func configure(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        
        let instanceId: String = try call.requireParameter(.instanceId)
        
        guard instances[instanceId] == nil else {
            throw PluginException(.wrongParameter, message: "PowerAuth instance is alread configured.")
        }
        
        let configuration: FlutterMap = try call.requireParameter(.configuration)
        
        guard let paConfig = PowerAuthConfiguration(instanceId: instanceId, arguments: configuration) else {
            throw PluginException(.wrongParameter, message: "Invalid PowerAuthConfiguration parameters.")
        }
        
        let pa = PowerAuthSDK(configuration: paConfig)
        instances[instanceId] = pa // TODO: object register!
        result(true)
    }
    
    private func deconfigure(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        instances.removeValue(forKey: try call.requireParameter(.instanceId))
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
            let data: Data?
            if let bodyString: String = call.getParameter(.body) {
                data = Data(base64Encoded: bodyString)
            } else {
                data = nil
            }
            
            result(try sdk.offlineSignature(with: auth, uriId: uriId, body: data, nonce: nonce))
        }
    }
    
    private func verifyServerSignedData(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, _ in
            
            let dataString: String = try call.requireParameter(.data)
            let signature: String = try call.requireParameter(.signature)
            let masterKey: Bool = try call.requireParameter(.useMasterKey)
            
            guard let data: Data = Data(base64Encoded: dataString) else {
                // TODO: consider returning an error?
                result(false)
                return
            }
            
            let verifyResult = sdk.verifyServerSignedData(data, signature: signature, masterKey: masterKey)
            result(verifyResult)
            
        }
    }
    
    // MARK: PowerAuth Helper methods
    
    private typealias WrapThrowBlock = (() throws -> Void) -> Void
    
    private func usePowerAuth(_ call: FlutterMethodCall, _ result: @escaping FlutterResult, _ block: (PowerAuthSDK, @escaping WrapThrowBlock) throws -> Void) throws {
        
        guard let instance = instances[try call.requireParameter(.instanceId)] else {
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
                    // TODO: not implemented yet
                    fatalError("Not implemented")
//                    PowerAuthData * biometryKeyData = [_objectRegister useObjectWithId:biometryKeyId expectedClass:[PowerAuthData class]];
//                    if (biometryKeyData) {
//                        return [PowerAuthAuthentication possessionWithBiometryWithCustomBiometryKey:biometryKeyData.data customPossessionKey:nil];
//                    } else {
//                        reject(EC_INVALID_NATIVE_OBJECT, @"Biometric key in PowerAuthAuthentication object is no longer valid.", nil);
//                        return nil;
//                    }
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
}

enum PowerAuthFlutterError: String {
    case networkError
    case signatureError
    case invalidActivationState
    case invalidActivationData
    case missingActivation
    case pendingActivation
    case operationCanceled
    case invalidToken
    case invalidEncryptor
    case encryptionError
    case wrongParameter
    case protocolUpgrade
    case pendingProtocolUpgrade
    case watchConnectivity
    case biometryCancel
    case biometryFallback
    case biometryFailed
    case biometryLockout
    case biometryNotAvailable
    case biometryNotSupported
    case biometryNotConfigured
    case biometryNotEnrolled
    case authenticationError
    case responseError
    case unknownError
    case reactNativeError
    case invalidActivationObject
    case invalidActivationCode
    case invalidCharacter
    case localTokenNotAvailable
    case cannotGenerateToken
    case instanceNotConfigured
    case invalidNativeObject
    case timeSynchronization
    case externalPendingOperation
    
    static func from(_ code: PowerAuthErrorCode) -> PowerAuthFlutterError {
        return switch (code) {
        case .networkError:   .networkError
        case .signatureError: .signatureError
        case .invalidActivationState: .invalidActivationState
        case .invalidActivationData: .invalidActivationData
        case .missingActivation: .missingActivation
        case .activationPending: .pendingActivation
        case .biometryCancel: .biometryCancel
        case .operationCancelled: .operationCanceled
        case .invalidActivationCode: .invalidActivationCode
        case .invalidToken: .invalidToken
        case .encryption: .encryptionError
        case .wrongParameter: .wrongParameter
        case .protocolUpgrade: .protocolUpgrade
        case .pendingProtocolUpgrade: .pendingProtocolUpgrade
        case .biometryNotAvailable: .biometryNotAvailable
        case .watchConnectivity: .watchConnectivity
        case .biometryFailed: .biometryFailed
        case .biometryFallback: .biometryFallback
        case .timeSynchronization: .timeSynchronization
        case .NA: .unknownError // TODO: other handling?
        case .externalPendingOperation: .externalPendingOperation
        @unknown default: .unknownError // TODO: additional handling, maybe pass it to the message?
        }
    }
}

extension FlutterError {
    
    convenience init(thrownByPlugin: Error) {
        if let pe = thrownByPlugin as? PluginException {
            self.init(code: pe.code, message: pe.message, details: pe.details)
            return
        }
        
        var errorCode: PowerAuthFlutterError
        var message: String
        var details: Any? = thrownByPlugin.localizedDescription
        
        // all PowerAuth errors are NSErrors
        let error = thrownByPlugin as NSError
        message = error.localizedDescription
        // If powerAuthErrorCode is different than .NA, then it's PowerAuthDomain error.
        let paErrorCode = error.powerAuthErrorCode
        if paErrorCode != PowerAuthErrorCode.NA {
            // Handle PA error
            if let responseData = error.userInfo[PowerAuthErrorInfoKey_AdditionalInfo] as? FlutterMap {
                // Handle error response received from the server. In this case, we have to re-create the error in a nice-to-serialize manner
                let responseObject = error.userInfo[PowerAuthErrorDomain] as? PowerAuthRestApiErrorResponse
                let httpStatusCode = responseObject?.httpStatusCode
                if (httpStatusCode == 401) {
                    errorCode = .authenticationError
                    message = "Unauthorized"
                } else {
                    errorCode = .responseError
                    message = "Wrong HTTP status code received from the server"
                }
                var newUserInfo: FlutterMap = [NSLocalizedDescriptionKey: message]
                if let responseObject {
                    newUserInfo["httpStatusCode"] = httpStatusCode
                    // Serialize dictionary back to string, to be compatible with Android
                    if let jsonData = try? JSONSerialization.data(withJSONObject: responseData as Any) {
                        if let jsonString = String(data: jsonData, encoding: .utf8) {
                            newUserInfo["responseBody"] = jsonString
                        }
                    }
                    if let serverResponseCode = responseObject.responseObject.code {
                        newUserInfo["serverResponseCode"] = serverResponseCode
                    }
                    if let serverResponseMessage = responseObject.responseObject.message {
                        newUserInfo["serverResponseMessage"] = serverResponseMessage
                    }
                }
                // Finally, build a new error
                details = [
                    "domain": PowerAuthErrorDomain,
                    "code": error.code,
                    "userInfo": newUserInfo
                ]
                //
            } else {
                // Other type of PowerAuthError. Just translate errorCode to string and keep NSError as it is.
                errorCode = .from(paErrorCode)
                //
            }
        } else if error.domain  == NSURLErrorDomain {
            // Handle error from NSURLSession
            errorCode = .networkError
            //
        } else {
            // We don't know this domain, so translate result as an UNKNOWN_ERROR
            errorCode = .unknownError
            //
        }
        
        // creat the code...
        self.init(code: errorCode, message: message, details: details)
    }
    
    private convenience init(code: PowerAuthFlutterError, message: String?, details: Any?) {
        self.init(code: code.rawValue, message: message, details: details)
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

private struct PluginException: Error {
    
    let code: PowerAuthFlutterError
    let message: String?
    let details: Any?
    
    init(_ code: PowerAuthFlutterError, message: String? = nil, details: Any? = nil) {
        self.code = code
        self.message = message
        self.details = details
    }
}

extension FlutterMethodCall {
    
    func requireParameter<T>(_ key: PowerAuthPlugin.ArgKeys) throws -> T {
        guard let parameter: T = getParameter(key) else {
            throw PluginException(.wrongParameter, message: "Failed to retrieve required parameter \(key)")
        }
        return parameter
    }
    
    func getParameter<T>(_ key: PowerAuthPlugin.ArgKeys) -> T? {
        guard let arguments = arguments as? FlutterMap else {
            return nil
        }
        
        return arguments.get(key)
    }
}

private typealias FlutterMap = [String: Any]

private extension FlutterMap {
    func get<T>(_ key: PowerAuthPlugin.ArgKeys) -> T? {
        return self[key.rawValue] as? T
    }
}
