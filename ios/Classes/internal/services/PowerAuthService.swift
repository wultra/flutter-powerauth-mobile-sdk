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
    
    let name = "PowerAuth"
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
    fileprivate enum Args: String {
        case instanceId
        case configuration
        case clientConfiguration
        case biometryConfiguration
        case keychainConfiguration
        case sharingConfiguration
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
        case isReusable
        case isBiometry
        case isPersist
        case accessGroupName
        case userDefaultsSuiteName
        case linkItemsToCurrentSet
        case fallbackToDevicePasscode
        case appGroup
        case appIdentifier
        case keychainAccessGroup
        case sharedMemoryIdentifier
        case customHttpHeaders
        case basicHttpAuthentication
        case connectionTimeout
        case enableUnsecureTraffic
        case name
        case value
        case username
    }
    
    private func isConfigured(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        let instanceId: String = try call.requireParameter(Args.instanceId)
        let sdk: PowerAuthSDK? = register.find(id: instanceId)
        result(sdk != nil)
    }
    
    private func configure(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        
        let instanceId: String = try call.requireParameter(Args.instanceId)
        
        let configuration: FlutterMap = try call.requireParameter(Args.configuration)
        
        guard let paConfig = PowerAuthConfiguration(instanceId: instanceId, arguments: configuration) else {
            throw PluginException(.wrongParameter, message: "Invalid PowerAuthConfiguration parameters.")
        }
        
        if let sharingConfiguration: FlutterMap = call.getParameter(Args.sharingConfiguration) {
            let sharingConfig = PowerAuthSharingConfiguration(
                appGroup: try sharingConfiguration.require(Args.appGroup),
                appIdentifier: try sharingConfiguration.require(Args.appIdentifier),
                keychainAccessGroup: try sharingConfiguration.require(Args.keychainAccessGroup)
            )
            sharingConfig.sharedMemoryIdentifier = sharingConfiguration.get(Args.sharedMemoryIdentifier)
            paConfig.sharingConfiguration = sharingConfig
        }
        
        guard paConfig.validate() else {
            throw PluginException(.wrongParameter, message: "Provided configuration is invalid")
        }
        
        let clientConfiguration: FlutterMap? = call.getParameter(Args.clientConfiguration)
        let timeout: TimeInterval? = clientConfiguration?.get(Args.connectionTimeout)
        let enableUnsecureTraffic: Bool? = clientConfiguration?.get(Args.enableUnsecureTraffic)
        var clientConfig: PowerAuthClientConfiguration?
        
        if timeout != nil || enableUnsecureTraffic != nil {
            let cc = PowerAuthClientConfiguration()
            cc.defaultRequestTimeout = timeout ?? cc.defaultRequestTimeout
            if enableUnsecureTraffic == true {
                cc.sslValidationStrategy = PowerAuthClientSslNoValidationStrategy()
            }
            clientConfig = cc
        }
        
        var interceptors = [PowerAuthCustomHeaderRequestInterceptor]()
        
        // http headers
        if let httpHeaders: [FlutterMap] = clientConfiguration?.get(Args.customHttpHeaders) {
            for header in httpHeaders {
                if let name: String = header.get(Args.name), let value: String = header.get(Args.value) {
                    interceptors.append(PowerAuthCustomHeaderRequestInterceptor(headerKey: name, value: value))
                }
            }
        }
        
        // Basic Authentication
        if
            let basicAuth: FlutterMap = clientConfiguration?.get(Args.basicHttpAuthentication),
            let username: String = basicAuth.get(Args.username),
            let password: String = basicAuth.get(Args.password) {
            interceptors.append(PowerAuthCustomHeaderRequestInterceptor(headerKey: username, value: password))
        }
        
        if interceptors.isEmpty == false {
            clientConfig = clientConfig ?? PowerAuthClientConfiguration()
            clientConfig!.requestInterceptors = interceptors
        }
        
        var keychainConfig: PowerAuthKeychainConfiguration?
        let keychainConfiguration: FlutterMap? = call.getParameter(Args.keychainConfiguration)
        let biometryConfiguration: FlutterMap? = call.getParameter(Args.biometryConfiguration)
        
        // only create PowerAuthKeychainConfiguration if one of the config is configured
        if keychainConfiguration != nil || biometryConfiguration != nil {
            
            let kc = PowerAuthKeychainConfiguration()
            
            // Keychain specific
            if let keychainConfiguration {
                kc.keychainAttribute_AccessGroup = keychainConfiguration.get(Args.accessGroupName)
                kc.keychainAttribute_UserDefaultsSuiteName = keychainConfiguration.get(Args.userDefaultsSuiteName)
            }
            
            // Biometry
            if let biometryConfiguration {
                kc.linkBiometricItemsToCurrentSet = biometryConfiguration.get(Args.linkItemsToCurrentSet, defaultValue: kc.linkBiometricItemsToCurrentSet)
                kc.allowBiometricAuthenticationFallbackToDevicePasscode = biometryConfiguration.get(Args.fallbackToDevicePasscode, defaultValue: kc.allowBiometricAuthenticationFallbackToDevicePasscode)
            }
            
            keychainConfig = kc
        }
        
        guard let sdk = PowerAuthSDK(configuration: paConfig, keychainConfiguration: keychainConfig, clientConfiguration: clientConfig) else {
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
        let instanceId: String = try call.requireParameter(Args.instanceId)
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
            let activation: FlutterMap = try call.requireParameter(Args.activation)
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
                    guard let activationResult else {
                        throw error ?? PluginException(.unknownError, message: "Unknown error occurred.")
                    }
                    
                    result([
                        "activationFingerprint": activationResult.activationFingerprint,
                        "customAttributes": activationResult.customAttributes ?? [:]
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
            
            let passParam: FlutterMap = try call.requireParameter(Args.password)
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
            
            let oldPassParam: FlutterMap = try call.requireParameter(Args.oldPassword)
            let newPassParam: FlutterMap = try call.requireParameter(Args.newPassword)
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
            let uriId: String = try call.requireParameter(Args.uriId)
            let nonce: String = try call.requireParameter(Args.nonce)
            let bodyString: String? = call.getParameter(Args.body)
            let data = bodyString?.data(using: .utf8)
            
            result(try sdk.offlineSignature(with: auth, uriId: uriId, body: data, nonce: nonce))
        }
    }
    
    private func verifyServerSignedData(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, _ in
            
            let stringData: String = try call.requireParameter(Args.data)
            let signature: String = try call.requireParameter(Args.signature)
            let masterKey: Bool = call.getParameter(Args.useMasterKey) ?? false
            
            guard let data = stringData.data(using: .utf8) else {
                throw PluginException(.unknownError, message: "Failed to convert string to data")
            }
            
            let verifyResult = sdk.verifyServerSignedData(data, signature: signature, masterKey: masterKey)
            result(verifyResult)
        }
    }
    
    private func requestGetSignature(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, _ in
            
            let auth = try constructAuthentication(call)
            let uriId: String = try call.requireParameter(Args.uriId)
            let queryparams: [String: String]? = call.getParameter(Args.queryParams)
            
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
            let uriId: String = try call.requireParameter(Args.uriId)
            let method: String = try call.requireParameter(Args.method)
            
            let bodyString: String? = call.getParameter(Args.body)
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
            let passParam: FlutterMap = try call.requireParameter(Args.password)
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
            
            // validate if the biometry is available first
            switch PowerAuthKeychain.biometricAuthenticationInfo.currentStatus {
            case .available:
                if sdk.hasValidActivation() && !sdk.hasBiometryFactor() {
                    throw PluginException(.biometryNotConfigured, message: "Biometry factor is not configured")
                }
            case .notEnrolled:
                throw PluginException(.biometryNotEnrolled, message: "Biometry is not enrolled on device")
            case .notSupported:
                throw PluginException(.biometryNotSupported, message: "Biometry is not supported")
            case .notAvailable:
                throw PluginException(.biometryNotAvailable, message: "Biometry is not available")
            case .lockout:
                throw PluginException(.biometryLockout, message: "Biometry is locked out")
            default:
                break
            }
            
            let prompt: FlutterMap = try call.requireParameter(Args.prompt)
            let isReusable = call.getParameter(Args.isReusable) ?? false
            
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
                    
                    // If reusable authentication is going to be created, then "keep alive" release policy is applied.
                    // Basically, the data will be available up to 10 seconds from the last access.
                    // If authentication is not reusable, then dispose biometric key after its 1st use. We still need
                    // to combine it with "expire" policy to make sure that key don't remain in memory forever.
                    var policy = [ReleasePolicy.keepAlive(Constants.BIOMETRY_KEY_KEEP_ALIVE_TIME)]
                    if isReusable == false {
                        policy.append(.afterUse(1))
                    }
                    
                    let managedId = self.register.add(object: managedData, tag: sdk.configuration.instanceId, policies: policy)
                    result(managedId)
                }
            }
        }
    }
    
    // MARK: PowerAuth Helper methods
    
    private func usePowerAuth(_ call: FlutterMethodCall, _ result: @escaping FlutterResult, _ block: (PowerAuthSDK, @escaping WrapThrowBlock) throws -> Void) throws {
        try register.usePowerAuthSDK(id: try call.requireParameter(Args.instanceId), result, block)
    }
    
    private func usePassword(_ dict: FlutterMap?) throws -> PowerAuthCorePassword {
        return try register.usePassword(dict: dict)
    }
    
    private func constructAuthentication(_ call: FlutterMethodCall) throws -> PowerAuthAuthentication {
        
        let dict: FlutterMap = try call.requireParameter(Args.authentication)
        let useBiometry = dict.get(Args.isBiometry, defaultValue: false)
        let persist = dict.get(Args.isPersist, defaultValue: false)
        
        let userPassword: FlutterMap? = dict.get(Args.password)
        
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
                    guard let biometryKeyData: PowerAuthData = register.use(id: biometryKeyId) else {
                        throw PluginException(.invalidNativeObject, message: "Biometric key in PowerAuthAuthentication object is no longer valid.")
                    }
                    return PowerAuthAuthentication.possessionWithBiometry(customBiometryKey: biometryKeyData.data, customPossessionKey: nil)
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
