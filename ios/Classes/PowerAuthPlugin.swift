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

        // Similarly to CDV, args are passed as part of the `FlutterMethodCall` object
        // guard let arguments = call.arguments as? [String: Any] else {
        //     // Error here?
        //     return
        // }
        
        switch call.method {
        case "configure": configure(call, result)
        case "isConfigured": isConfigured(call, result)
        case "deconfigure": deconfigure(call, result)
        case "hasValidActivation": hasValidActivation(call, result)
        case "canStartActivation": canStartActivation(call, result)
        case "hasPendingActivation": hasPendingActivation(call, result)
        case "getActivationIdentifier": getActivationIdentifier(call, result)
        case "getActivationFingerprint": getActivationFingerprint(call, result)
        case "fetchActivationStatus": fetchActivationStatus(call, result)
        case "removeActivationLocal": removeActivationLocal(call, result)
        case "removeActivationWithAuthentication": removeActivationWithAuthentication(call, result)
            // "getExternalPendingOperation" -> getExternalPendingOperation(instanceId, result)
        case "createActivation": createActivation(call, result)
        case "persistActivation": persistActivation(call, result)
            // "validatePassword" -> validatePassword(call, instanceId, result)
            // "changePassword" -> changePassword(call, instanceId, result)
            // "unsafeChangePassword" -> unsafeChangePassword(call, instanceId, result)
            // "requestGetSignature" -> requestGetSignature(call, instanceId, result)
            // "requestSignature" -> requestSignature(call, instanceId, result)
            // "offlineSignature" -> offlineSignature(call, instanceId, result)
            // "verifyServerSignedData" -> verifyServerSignedData(call, instanceId, result)
        case "getPlatformVersion": result("iOS " + UIDevice.current.systemVersion)

        default:
            print("PowerAuthPlugin received unexpected method: \(call.method)")
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - POWERAUTH PLUGIN API CODE
    
    private var instances = [String: PowerAuthSDK]()
    
    private func isConfigured(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        result(getPowerAuthInstance(call) != nil)
    }
    
    private func configure(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        
        guard let instanceId = getInstanceIdParameter(call) else {
            result(
                FlutterError(
                    code: PowerAuthFlutterError.wrongParameter,
                    message: "Missing instanceId parameter",
                    details: nil
                )
            )
            return
        }
        
        guard getPowerAuthInstance(instanceId) == nil else {
            result(
                FlutterError(
                    code: PowerAuthFlutterError.wrongParameter, // TODO: error code?
                    message: "PowerAuth instance is alread configured.",
                    details: nil
                )
            )
            return
        }
        
        guard let configuration: [String: Any] = getParameter("configuration", call, result) else {
            return
        }
        
        guard let paConfig = PowerAuthConfiguration(instanceId: instanceId, arguments: configuration) else {
            result(
                FlutterError(
                    code: PowerAuthFlutterError.wrongParameter,
                    message: "Invalid PowerAuthConfiguration parameters.",
                    details: nil
                )
            )
            return
        }
        
        let pa = PowerAuthSDK(configuration: paConfig)
        instances[instanceId] = pa // TODO: object register!
        result(true)
    }
    
    private func deconfigure(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        
        guard let instanceId = getInstanceIdParameter(call) else {
            result(
                FlutterError(
                    code: PowerAuthFlutterError.wrongParameter,
                    message: "Missing instanceId parameter",
                    details: nil
                )
            )
            return
        }
        
        instances.removeValue(forKey: instanceId)
        result(true)
    }
    
    private func hasValidActivation(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        usePowerAuth(call, result) { pa in
            result(pa.hasValidActivation())
        }
    }
    
    private func canStartActivation(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        usePowerAuth(call, result) { pa in
            result(pa.canStartActivation())
        }
    }
    
    private func hasPendingActivation(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        usePowerAuth(call, result) { pa in
            result(pa.hasPendingActivation())
        }
    }
    
    private func getActivationIdentifier(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        usePowerAuth(call, result) { pa in
            result(pa.activationIdentifier)
        }
    }
    
    private func getActivationFingerprint(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        usePowerAuth(call, result) { pa in
            result(pa.activationFingerprint)
        }
    }
    
    private func fetchActivationStatus(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        usePowerAuth(call, result) { pa in
            
            pa.fetchActivationStatus { status, error in
                
                guard let status else {
                    result(FlutterError(powerAuthError: error))
                    return
                }
                
                let response: [String: Any?] = [
                    "state": status.state.serializable,
                    "failCount": status.failCount,
                    "maxFailCount": status.maxFailCount,
                    "remainingAttempts": status.remainingAttempts,
                    "customObject": status.customObject
                ]
                
                result(response)
            }
        }
    }
    
    private func removeActivationLocal(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        usePowerAuth(call, result) { pa in
            pa.removeActivationLocal()
            result(true)
        }
    }
    
    private func removeActivationWithAuthentication(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        usePowerAuth(call, result) { pa in
            
            guard let auth = constructAuthentication(call, result, persist: false) else {
                return
            }
            
            pa.removeActivation(with: auth) { error in
                if let error {
                    result(FlutterError(powerAuthError: error))
                } else {
                    result(true)
                }
            }
        }
    }
    
    private func createActivation(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        usePowerAuth(call, result) { pa in
            
            var paActivation: PowerAuthActivation?
            
            guard let activation: [String: Any] = getParameter("activation", call, result) else {
                return
            }
                
            let name = activation["activationName"] as? String
            
            if let activationCode = activation["activationCode"] as? String {
                do {
                    paActivation = try PowerAuthActivation(activationCode: activationCode, name: name)
                } catch let e {
                    result(FlutterError(code: .invalidActivationObject, message: "Invalid activation code provided", details: e.localizedDescription))
                    return
                }
            } else if let identityAttributes = activation["identityAttributes"] as? [String: String] {
                do {
                    paActivation = try PowerAuthActivation(identityAttributes: identityAttributes, name:name)
                } catch let e {
                    result(FlutterError(code: .invalidActivationObject, message: "Invalid identity attributes provided", details: e.localizedDescription))
                    return
                }
            }
            
            guard let paActivation else {
                result(FlutterError(code: .invalidActivationObject, message: "Activation object is invalid.", details: nil))
                return
            }
            
            if let extras = activation["extras"] as? String {
                paActivation.with(extras: extras)
            }
            
            if let customAttributes = activation["customAttributes"] as? [String: Any] {
                paActivation.with(customAttributes: customAttributes)
            }
            
            if let otp = activation["additionalActivationOtp"] as? String {
                paActivation.with(additionalActivationOtp: otp)
            }
            
            pa.createActivation(paActivation) { activationResult, error in
                
                guard let activationResult else {
                    result(FlutterError(powerAuthError: error))
                    return
                }
                
                result([
                    "activationFingerprint": activationResult.activationFingerprint,
                    "customAttributes": activationResult.customAttributes
                ])
            }
        }
    }
    
    func persistActivation(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        usePowerAuth(call, result) { pa in
            
            guard let auth = constructAuthentication(call, result, persist: true) else {
                return
            }
            
            do {
                try pa.persistActivation(with: auth)
                result(nil)
            } catch let e {
                result(FlutterError(powerAuthError: e))
            }
        }
    }
    
    // MARK: PowerAuth Helper methods
    
    private func usePowerAuth(_ call: FlutterMethodCall, _ result: @escaping FlutterResult, _ block: (PowerAuthSDK) -> Void) {
        
        guard let instance = getPowerAuthInstance(call) else {
            result(
                FlutterError(
                    code: PowerAuthFlutterError.instanceNotConfigured,
                    message: "PowerAuth instance not configured.",
                    details: nil
                )
            )
            return
        }
        
        block(instance)
    }
    
    private func getPowerAuthInstance(_ call: FlutterMethodCall) -> PowerAuthSDK? {
        guard let instanceId = getInstanceIdParameter(call) else {
            return nil
        }
        return getPowerAuthInstance(instanceId)
    }
    
    private func getPowerAuthInstance(_ instanceId: String) -> PowerAuthSDK? {
        return instances[instanceId]
    }
    
    private func getInstanceIdParameter(_ call: FlutterMethodCall) -> String? {
        return getParameter("instanceId", call, nil)
    }
    
    private func getParameter<T>(_ key: String, _ call: FlutterMethodCall, _ result: FlutterResult?) -> T? {
        guard let arguments = call.arguments as? [String: Any] else {
            result?(
                FlutterError(
                    code: PowerAuthFlutterError.wrongParameter,
                    message: "Invalid arguments format. Expecting a Map<String, dynamic>.",
                    details: nil
                )
            )
            return nil
        }
        
        return getParameter(key, arguments, result)
    }
    
    private func getParameter<T>(_ key: String, _ arguments: [String: Any], _ result: FlutterResult?) -> T? {
        guard let parameter = arguments[key] as? T else {
            result?(
                FlutterError(
                    code: PowerAuthFlutterError.wrongParameter,
                    message: "Unexpected parameter format. Expecting \(key) to be of type \(String(describing: T.self)).",
                    details: nil
                )
            )
            return nil
        }
        
        return parameter
    }
    
    func usePassword(dict: [String: Any]?, result: FlutterResult) -> PowerAuthCorePassword? {
        // TODO: we don't use object register yet, so just take plain password until implemented properly
        guard let dict, let password = dict["password"] as? String else {
            result(
                FlutterError(
                    code: PowerAuthFlutterError.wrongParameter,
                    message: "Failed to parse provided password",
                    details: nil
                )
            )
            return nil
        }
        return PowerAuthCorePassword(string: password)
    }
    
    private func constructAuthentication(_ call: FlutterMethodCall, _ result: @escaping FlutterResult, persist: Bool) -> PowerAuthAuthentication? {
        
        guard let dict: [String: Any] = getParameter("authentication", call, result) else {
            return nil
        }
        
        let useBiometry = dict["isBiometry"] as? Bool ?? false // TODO: fallback ok?
        
        let userPassword: [String: Any]? = getParameter("password", dict, nil)
        
        if persist {
            // Activation persist
            guard let password = usePassword(dict: userPassword, result: result) else {
                return nil
            }
            if useBiometry {
                // All factors needs to be estabilished in activation.
                return PowerAuthAuthentication.persistWithPasswordAndBiometry(password: password)
            } else {
                return PowerAuthAuthentication.persistWithPassword(password: password)
            }
        } else {
            // Data signing
            if let userPassword {
                guard let password = usePassword(dict: userPassword, result: result) else {
                    return nil
                }
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
    
    convenience init(code: PowerAuthFlutterError, message: String?, details: Any?) {
        self.init(code: code.rawValue, message: message, details: details)
    }
    
    // TODO: this is converted 1:1 from React-Native - improve if necessary
    
    // expecing NSError thrown from PowerAuthSDK object
    convenience init(powerAuthError: Error?) {
        
        var errorCode: PowerAuthFlutterError
        var message: String
        var details: Any? = powerAuthError?.localizedDescription
        
        // all PowerAuth errors are NSErrors
        if let error = powerAuthError as? NSError {
            message = error.localizedDescription
            // If powerAuthErrorCode is different than .NA, then it's PowerAuthDomain error.
            let paErrorCode = error.powerAuthErrorCode
            if paErrorCode != PowerAuthErrorCode.NA {
                // Handle PA error
                if let responseData = error.userInfo[PowerAuthErrorInfoKey_AdditionalInfo] as? [String: Any] {
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
                    var newUserInfo: [String: Any] = [NSLocalizedDescriptionKey: message]
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
        } else {
            errorCode = .unknownError
            message = "Native code failed with unspecified error"
        }
        
        // creat the code...
        self.init(code: errorCode, message: message, details: details)
    }
}

extension PowerAuthConfiguration {
    convenience init?(instanceId: String, arguments: [String: Any]) {
        guard
            let sdkConfig = arguments["configuration"] as? String,
            let baseEndpointUrl = arguments["baseEndpointUrl"] as? String
            else {
            return nil
        }
        
        self.init(instanceId: instanceId, baseEndpointUrl: baseEndpointUrl, configuration: sdkConfig)
    }
}

extension PowerAuthActivationState {
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
