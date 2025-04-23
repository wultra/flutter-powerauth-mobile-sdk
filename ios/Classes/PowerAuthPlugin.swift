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
            // "deconfigure" -> deconfigure(instanceId, result)
            // "hasValidActivation" -> hasValidActivation(instanceId, result)
            // "canStartActivation" -> canStartActivation(instanceId, result)
            // "hasPendingActivation" -> hasPendingActivation(instanceId, result)
            // "getActivationIdentifier" -> getActivationIdentifier(instanceId, result)
            // "getActivationFingerprint" -> getActivationFingerprint(instanceId, result)
            // "fetchActivationStatus" -> fetchActivationStatus(instanceId, result)
            // "removeActivationLocal" -> removeActivationLocal(instanceId, result)
            // "removeActivationWithAuthentication" -> removeActivationWithAuthentication(call, instanceId, result)
            // "getExternalPendingOperation" -> getExternalPendingOperation(instanceId, result)
            // "createActivation" -> createActivation(call, instanceId, result)
            // "persistActivation" -> persistActivation(call, instanceId, result)
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
                    code: PowerAuthErrorCode.wrongParameter,
                    message: "Missing instanceId parameter",
                    details: nil
                )
            )
            return
        }
        
        guard getPowerAuthInstance(instanceId) == nil else {
            result(
                FlutterError(
                    code: PowerAuthErrorCode.wrongParameter,
                    message: "PowerAuth instance is alread configured.", // TODO: error code?
                    details: nil
                )
            )
            return
        }
        
        guard let configuration: [String: Any] = getParameter("configuration", call, result) else {
            return
        }
        
        guard let sdkConfig: String = getParameter("configuration", configuration, result) else {
            return
        }
        
        guard let baseEndpointUrl: String = getParameter("baseEndpointUrl", configuration, result) else {
            return
        }
        
        let paConfig = PowerAuthConfiguration(instanceId: instanceId, baseEndpointUrl: baseEndpointUrl, configuration: sdkConfig)
        let pa = PowerAuthSDK(configuration: paConfig)
        instances[instanceId] = pa // TODO: object register!
        result(true)
    }
    
    // MARK: PowerAuth Helper methods
    
    private func usePowerAuth(_ call: FlutterMethodCall, _ result: @escaping FlutterResult, _ block: (PowerAuthSDK) -> Void) {
        
        guard let instance = getPowerAuthInstance(call) else {
            result(
                FlutterError(
                    code: PowerAuthErrorCode.instanceNotConfigured,
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
                    code: PowerAuthErrorCode.wrongParameter,
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
                    code: PowerAuthErrorCode.wrongParameter,
                    message: "Unexpected parameter format. Expecting \(key) to be of type \(String(describing: T.self)).",
                    details: nil
                )
            )
            return nil
        }
        
        return parameter
    }
}

enum PowerAuthErrorCode: String {
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
}

extension FlutterError {
    
    convenience init(code: PowerAuthErrorCode, message: String?, details: Any?) {
        self.init(code: code.rawValue, message: message, details: details)
    }
}
