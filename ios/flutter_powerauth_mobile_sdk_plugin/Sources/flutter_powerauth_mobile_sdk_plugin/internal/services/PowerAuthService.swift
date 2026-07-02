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

internal class PowerAuthService: PowerAuthFlutterService {
    
    let name = "PowerAuth"
    private let register: PowerAuthObjectRegister
    
    init(register: PowerAuthObjectRegister) {
        self.register = register
    }
    
    let handlers = [
        "configure": configure,
        "cleanupInstanceData": cleanupInstanceData,
        "isConfigured": isConfigured,
        "getConfiguration": getConfiguration,
        "getCurrentAlgorithm": getCurrentAlgorithm,
        //TODO: Implements when SDK 2.0.0 is available
        // "getClientConfiguration": getClientConfiguration,
        // "getBiometryConfiguration": getBiometryConfiguration,
        // "getKeychainConfiguration": getKeychainConfiguration,
        // "getSharingConfiguration": getSharingConfiguration,
        "deconfigure": deconfigure,
        "hasValidActivation": hasValidActivation,
        "canStartActivation": canStartActivation,
        "hasPendingActivation": hasPendingActivation,
        "getExternalPendingOperation": getExternalPendingOperation,
        "getActivationIdentifier": getActivationIdentifier,
        "getActivationFingerprint": getActivationFingerprint,
        "fetchActivationStatus": fetchActivationStatus,
        "hasProtocolUpgradeAvailable": hasProtocolUpgradeAvailable,
        "hasPendingProtocolUpgrade": hasPendingProtocolUpgrade,
        "startProtocolUpgrade": startProtocolUpgrade,
        "removeActivationLocal": removeActivationLocal,
        "removeActivationWithAuthentication": removeActivationWithAuthentication,
        "createActivation": createActivation,
        "persistActivation": persistActivation,
        "beginPasswordChange": beginPasswordChange,
        "finishPasswordChange": finishPasswordChange,
        "authenticationHeaderForRequestWithParams": authenticationHeaderForRequestWithParams,
        "authenticationHeaderForRequestWithBody": authenticationHeaderForRequestWithBody,
        "offlineSignature": offlineSignature,
        "verifyDigitalSignature": verifyDigitalSignature,
        "calculateDigitalSignature": calculateDigitalSignature,
        "exportDevicePublicKeys": exportDevicePublicKeys,
        "verifyJwsSignature": verifyJwsSignature,
        "calculateJwsSignature": calculateJwsSignature,
        "createCertificateSigningRequest": createCertificateSigningRequest,
        "getBiometricStatus": getBiometricStatus,
        "isAuthenticationWithBiometricsAvailable": isAuthenticationWithBiometricsAvailable,
        "addBiometryFactor": addBiometryFactor,
        "hasBiometryFactor": hasBiometryFactor,
        "removeBiometryFactor": removeBiometryFactor,
        "authenticateUsingBiometry": authenticateUsingBiometry,
        "fetchEncryptionKey": fetchEncryptionKey,
        "fetchSecureVaultKey": fetchSecureVaultKey,
        "deriveSecureVaultKey": deriveSecureVaultKey,
        "requestAccessToken": requestAccessToken,
        "removeAccessToken": removeAccessToken,
        "hasLocalToken": hasLocalToken,
        "getLocalToken": getLocalToken,
        "removeLocalToken": removeLocalToken,
        "removeAllLocalTokens": removeAllLocalTokens,
        "generateHeaderForToken": generateHeaderForToken,
        "fetchUserInfo": fetchUserInfo,
        "getLastFetchedUserInfo": getLastFetchedUserInfo,
        "isTimeSynchronized": isTimeSynchronized,
        "localTimeAdjustment": localTimeAdjustment,
        "localTimeAdjustmentPrecision": localTimeAdjustmentPrecision,
        "currentTime": currentTime,
        "synchronizeTime": synchronizeTime,
        "resetTimeSynchronization": resetTimeSynchronization
    ]
    
    // Possible Flutter call parameters
    fileprivate enum Args: String {
        case instanceId
        case configuration
        case algorithm
        case offlineAuthenticationCodeComponentLength
        case baseEndpointUrl
        case clientConfiguration
        case biometryConfiguration
        case sharingConfiguration
        case activation
        case authentication
        case password
        case oldPassword
        case newPassword
        case passwordChangeData
        case uriId
        case params
        case method
        case body
        case nonce
        case data
        case signature
        case signatureKeyId
        case format
        case compact
        case strict
        case dataType
        case distinguishedNames
        case subjectAltNames
        case prompt
        case isReusable
        case isBiometry
        case isPersist
        case invalidateBiometricFactorAfterChange
        case fallbackToDevicePasscode
        case appGroup
        case appIdentifier
        case keychainAccessGroup
        case customHttpHeaders
        case basicHttpAuthentication
        case connectionTimeout
        case defaultRequestTimeout
        case enableUnsecureTraffic
        case name
        case value
        case username
        case tokenName
        case index
        case keySize
        case keyIdentifier
        case objectId
    }
    
    private func isConfigured(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        let instanceId: String = try call.requireParameter(Args.instanceId)
        let sdk: PowerAuthSDK? = register.find(id: instanceId)
        result(sdk != nil)
    }
    
    private func configure(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        let instanceId: String = try call.requireParameter(Args.instanceId)
        let configuration: FlutterMap = try call.requireParameter(Args.configuration)
        let paConfig = try buildPowerAuthConfiguration(instanceId: instanceId, arguments: configuration)
        try applySharingConfiguration(call.getParameter(Args.sharingConfiguration), to: paConfig)

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
            interceptors.append(PowerAuthBasicHttpAuthenticationRequestInterceptor(username: username, password: password))
        }
        
        if interceptors.isEmpty == false {
            clientConfig = clientConfig ?? PowerAuthClientConfiguration()
            clientConfig!.requestInterceptors = interceptors
        }
        
        var biometricConfig: PowerAuthBiometricConfiguration?
        if let biometryConfiguration: FlutterMap = call.getParameter(Args.biometryConfiguration) {
            let bc = PowerAuthBiometricConfiguration()
            bc.invalidateBiometricFactorAfterChange = biometryConfiguration.get(
                Args.invalidateBiometricFactorAfterChange,
                defaultValue: bc.invalidateBiometricFactorAfterChange
            )
            bc.allowFallbackToDevicePasscode = biometryConfiguration.get(
                Args.fallbackToDevicePasscode,
                defaultValue: bc.allowFallbackToDevicePasscode
            )
            biometricConfig = bc
        }

        // PowerAuth 2.x keeps native keychain storage names internal on Apple platforms.
        // Activation sharing is configured on PowerAuthConfiguration above.
        let sdk = try PowerAuthSDK(
            configuration: paConfig,
            biometricConfiguration: biometricConfig,
            clientConfiguration: clientConfig,
            keychainConfiguration: nil
        )
        
        let registered = register.add(id: instanceId, tag: instanceId, policies: [.manual()]) {
            sdk
        }
        if registered {
            result(nil)
        } else {
            throw PluginException(.wrongParameter, message: "PowerAuth instance is already configured.")
        }
    }

    private func cleanupInstanceData(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        let instanceId: String = try call.requireParameter(Args.instanceId)
        let configuration: FlutterMap = try call.requireParameter(Args.configuration)
        let paConfig = try buildPowerAuthConfiguration(instanceId: instanceId, arguments: configuration)
        try applySharingConfiguration(call.getParameter(Args.sharingConfiguration), to: paConfig)
        _ = try PowerAuthSDK.cleanupInstanceData(
            configuration: paConfig,
            keychainConfiguration: nil
        )
        result(nil)
    }

    private func getConfiguration(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, _ in
            result(try sdk.configuration.serializable())
        }
    }

    private func getCurrentAlgorithm(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, _ in
            result(try sdk.currentAlgorithm.serializable)
        }
    }
    //TODO: implement when SDK 2.0.0 is available
    //
    // private func getClientConfiguration(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
    //     try usePowerAuth(call, result) { sdk, _ in
    //         result(sdk.clientConfiguration.serializable)
    //     }
    // }
    //
    // private func getBiometryConfiguration(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
    //     try usePowerAuth(call, result) { sdk, _ in
    //         result(sdk.keychainConfiguration.biometrySerializable)
    //     }
    // }
    //
    // private func getKeychainConfiguration(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
    //     try usePowerAuth(call, result) { sdk, _ in
    //         result(sdk.keychainConfiguration.serializable)
    //     }
    // }
    //
    // private func getSharingConfiguration(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
    //     try usePowerAuth(call, result) { sdk, _ in
    //         result(sdk.configuration.sharingConfiguration?.serializable)
    //     }
    // }

    private func deconfigure(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        let instanceId: String = try call.requireParameter(Args.instanceId)
        register.removeAll(tag: instanceId)
        result(nil)
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
    
    private func getExternalPendingOperation(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, _ in
            if let pendingOperation = sdk.externalPendingOperation {
                let externalOperationType = switch pendingOperation.externalOperationType {
                case .activation: "activation"
                case .protocolUpgrade: "protocolUpgrade"
                @unknown default:
                    throw PluginException(.unknownError, message: "Unknown native external operation type.")
                }
                result([
                    "externalOperationType": externalOperationType,
                    "externalApplicationId": pendingOperation.externalApplicationId
                ])
            } else {
                result(nil)
            }
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
                    guard let status else {
                        throw PluginException(.unknownError, message: "PowerAuth SDK returned neither an activation status nor an error.")
                    }
                    result(status.serializable)
                }
            }
        }
    }

    private func hasProtocolUpgradeAvailable(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, _ in
            result(sdk.hasProtocolUpgradeAvailable())
        }
    }

    private func hasPendingProtocolUpgrade(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, _ in
            result(sdk.hasPendingProtocolUpgrade())
        }
    }

    private func startProtocolUpgrade(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            let passwordMap: FlutterMap = try call.requireParameter(Args.password)
            let password = try self.usePassword(passwordMap).copyToImmutable()

            // Unlike Android, the Apple SDK preserves the biometric factor automatically and
            // therefore has no upgradeBiometry input or biometryFactorRemoved result.
            sdk.startProtocolUpgrade(password: password) { upgradeResult, error in
                wrap {
                    // Keep the immutable password captured until the asynchronous operation ends.
                    _ = password
                    if let error {
                        throw error
                    }
                    guard let upgradeResult else {
                        throw PluginException(.unknownError, message: "PowerAuth SDK returned neither a protocol upgrade result nor an error.")
                    }
                    result([
                        "activationStatusFetchRequired": upgradeResult.activationStatusFetchRequired,
                        "activationFingerprint": upgradeResult.activationFingerprint as Any
                    ])
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
            let auth = try constructAuthentication(call)
            sdk.removeActivation(with: auth) { error in
                wrap {
                    // Authentication owns copied credentials required by the native async task.
                    _ = auth
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
                paActivation = try PowerAuthActivation(activationCode: activationCode, name: name)
            } else if let identityAttributes = activation["identityAttributes"] as? [String: String] {
                paActivation = try PowerAuthActivation(identityAttributes: identityAttributes, name:name)
            } else if let oidcParameters = activation["oidcParameters"] as? [String: String] {
                
                guard let providerId = oidcParameters["providerId"],
                      let code = oidcParameters["code"],
                      let nonce = oidcParameters["nonce"] else {
                    throw PluginException(.invalidActivationObject, message: "Invalid OIDC parameters provided")
                }
                
                let codeVerifier = oidcParameters["codeVerifier"]
                
                paActivation = try PowerAuthActivation(oidcProviderId: providerId, code: code, nonce: nonce, codeVerifier: codeVerifier)
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
                    guard let activationResult else {
                        throw PluginException(.unknownError, message: "PowerAuth SDK returned neither an activation result nor an error.")
                    }
                    
                    result(activationResult.serializable)
                }
            }
        }
    }
    
    func persistActivation(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            let auth = try constructAuthentication(call)
            sdk.persistActivation(with: auth) { error in
                wrap {
                    _ = auth
                    if let error {
                        throw error
                    }
                    result(nil)
                }
            }
        }
    }

    func beginPasswordChange(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            let instanceId: String = try call.requireParameter(Args.instanceId)
            let oldPasswordMap: FlutterMap = try call.requireParameter(Args.oldPassword)
            let oldPassword = try self.usePassword(oldPasswordMap).copyToImmutable()
            sdk.beginPasswordChange(oldPassword: oldPassword) { changeData, error in
                wrap {
                    // Keep the copied password alive until native verification completes.
                    _ = oldPassword
                    if let error {
                        throw error
                    }
                    guard let changeData else {
                        throw PluginException(.unknownError, message: "PowerAuth SDK returned neither password change data nor an error.")
                    }
                    // Do not expose change data produced by an SDK that was deconfigured while
                    // the network request was running.
                    guard let objectId = self.register.add(
                        object: changeData,
                        ifOwnerMatches: sdk,
                        ownerId: instanceId,
                        policies: [.expire(Constants.PASSWORD_KEY_KEEP_ALIVE_TIME)]
                    ) else {
                        changeData.secureClear()
                        throw PluginException(.instanceNotConfigured, message: "PowerAuth instance is no longer configured.")
                    }
                    result(objectId)
                }
            }
        }
    }

    func finishPasswordChange(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            let newPasswordMap: FlutterMap = try call.requireParameter(Args.newPassword)
            let changeDataId: String = try call.requireParameter(Args.passwordChangeData)
            guard let changeData: PowerAuthPasswordChangeData = self.register.touch(id: changeDataId) else {
                throw PluginException(.invalidNativeObject, message: "Password change data object is no longer valid.")
            }
            let newPassword = try self.usePassword(newPasswordMap).copyToImmutable()
            sdk.finishPasswordChange(newPassword: newPassword, changeData: changeData) { error in
                wrap {
                    _ = newPassword
                    if let error {
                        throw error
                    }
                    let _: PowerAuthPasswordChangeData? = self.register.remove(id: changeDataId)
                    result(nil)
                }
            }
        }
    }
    
    private func offlineSignature(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            let auth = try constructAuthentication(call)
            let uriId: String = try call.requireParameter(Args.uriId)
            let nonce: String = try call.requireParameter(Args.nonce)
            let data = call.optionalDataParameter(Args.body)
            sdk.offlineAuthenticationCode(with: auth, uriId: uriId, body: data, nonce: nonce) { code, error in
                wrap {
                    _ = auth
                    if let error {
                        throw error
                    }
                    guard let code else {
                        throw PluginException(.unknownError, message: "PowerAuth SDK returned neither an offline authentication code nor an error.")
                    }
                    result(code)
                }
            }
        }
    }

    private func verifyDigitalSignature(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, _ in
            let signature = try call.requiredDataParameter(Args.signature)
            let data = try call.requiredDataParameter(Args.data)
            let signatureKeyIdValue: String = try call.requireParameter(Args.signatureKeyId)
            let key = try PowerAuthSignatureUtils.signatureKeyId(from: signatureKeyIdValue)
            _ = try sdk.verifyDigitalSignature(signature: signature, forData: data, withKey: key)
            result(nil)
        }
    }
    
    private func authenticationHeaderForRequestWithParams(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, _ in
            let auth = try constructAuthentication(call)
            let method: String = try call.requireParameter(Args.method)
            let uriId: String = try call.requireParameter(Args.uriId)
            let params: [String: String]? = call.getParameter(Args.params)
            let header = try sdk.authenticationHeaderForRequestWithParams(
                with: auth,
                method: method,
                uriId: uriId,
                params: params
            )
            result(header.serializable)
        }
    }
    
    private func authenticationHeaderForRequestWithBody(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, _ in
            let auth = try constructAuthentication(call)
            let uriId: String = try call.requireParameter(Args.uriId)
            let method: String = try call.requireParameter(Args.method)
            let data = call.optionalDataParameter(Args.body)
            let header = try sdk.authenticationHeaderForRequestWithBody(
                with: auth,
                method: method,
                uriId: uriId,
                body: data
            )
            result(header.serializable)
        }
    }

    private func calculateDigitalSignature(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            let data = try call.requiredDataParameter(Args.data)
            let signatureKeyIdValue: String = try call.requireParameter(Args.signatureKeyId)
            let key = try PowerAuthSignatureUtils.signatureKeyId(from: signatureKeyIdValue)
            let auth = try constructAuthentication(call)
            sdk.calculateDigitalSignature(authentication: auth, forData: data, withKey: key) { signature, error in
                wrap {
                    _ = auth
                    if let error {
                        throw error
                    }
                    guard let signature else {
                        throw PluginException(.unknownError, message: "PowerAuth SDK returned neither a digital signature nor an error.")
                    }
                    result(Data(signature))
                }
            }
        }
    }

    private func exportDevicePublicKeys(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, _ in
            let formatValue: String = try call.requireParameter(Args.format)
            let format: PowerAuthDevicePublicKeyFormat
            switch formatValue {
            case "der": format = .der
            case "raw": format = .raw
            default:
                throw PluginException(.wrongParameter, message: "Unknown device public key format: \(formatValue)")
            }
            let keys = try sdk.exportDevicePublicKeys(format: format)
            result(try keys.map { key in
                let keyType: String
                switch key.keyType {
                case .EC: keyType = "ec"
                case .ML_DSA: keyType = "mlDsa"
                @unknown default:
                    throw PluginException(.unknownError, message: "Unknown native signature key type.")
                }
                return [
                    "keyType": keyType,
                    "keyAlgorithm": key.keyAlgorithm,
                    "keyData": Data(key.keyData)
                ] as FlutterMap
            })
        }
    }

    private func verifyJwsSignature(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, _ in
            let signature: String = try call.requireParameter(Args.signature)
            let compact: Bool = try call.requireParameter(Args.compact)
            let strict: Bool = try call.requireParameter(Args.strict)
            let signatureKeyIdValue: String = try call.requireParameter(Args.signatureKeyId)
            let key = try PowerAuthSignatureUtils.signatureKeyId(from: signatureKeyIdValue)
            _ = try sdk.verifyJwsSignature(
                signature: signature,
                compact: compact,
                strict: strict,
                withKey: key
            )
            result(nil)
        }
    }

    private func calculateJwsSignature(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            let data = try call.requiredDataParameter(Args.data)
            let dataType: String? = call.getParameter(Args.dataType)
            let compact: Bool = try call.requireParameter(Args.compact)
            let signatureKeyIdValue: String = try call.requireParameter(Args.signatureKeyId)
            let key = try PowerAuthSignatureUtils.signatureKeyId(from: signatureKeyIdValue)
            let auth = try constructAuthentication(call)
            sdk.calculateJwsSignature(
                authentication: auth,
                forData: data,
                dataType: dataType,
                compact: compact,
                withKey: key
            ) { signature, error in
                wrap {
                    _ = auth
                    if let error {
                        throw error
                    }
                    guard let signature else {
                        throw PluginException(.unknownError, message: "PowerAuth SDK returned neither a JWS signature nor an error.")
                    }
                    result(signature)
                }
            }
        }
    }

    private func createCertificateSigningRequest(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            let distinguishedNames: [String: String] = try call.requireParameter(Args.distinguishedNames)
            let subjectAltNames: [String]? = call.getParameter(Args.subjectAltNames)
            let signatureKeyIdValue: String = try call.requireParameter(Args.signatureKeyId)
            let key = try PowerAuthSignatureUtils.signatureKeyId(from: signatureKeyIdValue)
            let auth = try constructAuthentication(call)
            sdk.createCertificateSigningRequest(
                authentication: auth,
                distinguishedNames: distinguishedNames,
                subjectAltNames: subjectAltNames,
                keyIdentifier: key
            ) { csr, error in
                wrap {
                    _ = auth
                    if let error {
                        throw error
                    }
                    guard let csr else {
                        throw PluginException(.unknownError, message: "PowerAuth SDK returned neither a certificate signing request nor an error.")
                    }
                    result(csr)
                }
            }
        }
    }

    private func getBiometricStatus(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, _ in
            result(sdk.biometricStatus.serializable)
        }
    }

    private func isAuthenticationWithBiometricsAvailable(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, _ in
            result(sdk.isAuthenticationWithBiometricsAvailable)
        }
    }

    private func addBiometryFactor(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            let passParam: FlutterMap = try call.requireParameter(Args.password)
            let password = try self.usePassword(passParam).copyToImmutable()
            sdk.addBiometryFactor(password: password) { error in
                wrap {
                    _ = password
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
            sdk.removeBiometryFactor { error in
                wrap {
                    if let error {
                        throw error
                    }
                    result(nil)
                }
            }
        }
    }
    
    private func authenticateUsingBiometry(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            let prompt: FlutterMap? = call.getParameter(Args.prompt)
            let isReusable = call.getParameter(Args.isReusable) ?? false
            let context = try PowerAuthBiometryUtils.authenticationContext(from: prompt)
            let instanceId: String = try call.requireParameter(Args.instanceId)
            // The native task is intentionally not exposed because the Dart API has no cancel handle.
            _ = sdk.authenticateUsingBiometry(withContext: context) { authentication, error in
                wrap {
                    if let error {
                        throw error
                    }
                    guard let authentication else {
                        throw PluginException(.unknownError, message: "PowerAuth SDK returned neither biometric authentication nor an error.")
                    }
                    guard let customBiometryKey = authentication.customBiometryKey else {
                        throw PluginException(.unknownError, message: "Missing customBiometryKey in authentication")
                    }
                    let managedData = PowerAuthSecureData(withData: customBiometryKey.sensitiveData)
                    
                    // If reusable authentication is going to be created, then "keep alive" release policy is applied.
                    // Basically, the data will be available up to 10 seconds from the last access.
                    // If authentication is not reusable, then dispose biometric key after its 1st use. We still need
                    // to combine it with "expire" policy to make sure that key don't remain in memory forever.
                    var policy = [ReleasePolicy.keepAlive(Constants.BIOMETRY_KEY_KEEP_ALIVE_TIME)]
                    if isReusable == false {
                        policy.append(.afterUse(1))
                    }
                    
                    guard let managedId = self.register.add(
                        object: managedData,
                        ifOwnerMatches: sdk,
                        ownerId: instanceId,
                        policies: policy
                    ) else {
                        throw PluginException(.instanceNotConfigured, message: "PowerAuth instance is no longer configured.")
                    }
                    result(managedId)
                }
            }
        }
    }
    
    private func fetchEncryptionKey(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            let index: Int = try call.requireParameter(Args.index)
            guard index >= 0 else {
                throw PluginException(.wrongParameter, message: "Encryption key index must not be negative.")
            }
            let auth = try constructAuthentication(call)
            
            sdk.fetchEncryptionKey(auth, index: UInt64(index)) { key, error in
                wrap {
                    _ = auth
                    if let error {
                        throw error
                    }
                    guard let key else {
                        throw PluginException(.unknownError, message: "PowerAuth SDK returned neither an encryption key nor an error.")
                    }
                    result(copySecureData(key))
                }
            }
        }
    }

    private func fetchSecureVaultKey(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            let instanceId: String = try call.requireParameter(Args.instanceId)
            let keyIdentifierValue: String = try call.requireParameter(Args.keyIdentifier)
            let keyIdentifier: PowerAuthSecureVaultKeyId
            switch keyIdentifierValue {
            case "knowledge": keyIdentifier = .knowledge
            case "knowledgeOrBiometry": keyIdentifier = .knowledgeOrBiometry
            default:
                throw PluginException(.wrongParameter, message: "Unknown Secure Vault key identifier: \(keyIdentifierValue)")
            }
            let auth = try constructAuthentication(call)
            sdk.fetchSecureVaultKey(authentication: auth, keyIdentifier: keyIdentifier) { key, error in
                wrap {
                    _ = auth
                    if let error {
                        throw error
                    }
                    guard let key else {
                        throw PluginException(.unknownError, message: "PowerAuth SDK returned neither a Secure Vault key nor an error.")
                    }
                    guard let objectId = self.register.add(
                        object: key,
                        ifOwnerMatches: sdk,
                        ownerId: instanceId,
                        policies: [.keepAlive(Constants.SECURE_VAULT_KEY_KEEP_ALIVE_TIME)]
                    ) else {
                        throw PluginException(.instanceNotConfigured, message: "PowerAuth instance is no longer configured.")
                    }
                    result(objectId)
                }
            }
        }
    }

    private func deriveSecureVaultKey(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        let objectId: String = try call.requireParameter(Args.objectId)
        let index: Int = try call.requireParameter(Args.index)
        let keySize: Int = try call.requireParameter(Args.keySize)
        guard index >= 0 else {
            throw PluginException(.wrongParameter, message: "Secure Vault key index must not be negative.")
        }
        guard keySize >= 16 else {
            throw PluginException(.wrongParameter, message: "Secure Vault derived key size must be at least 16 bytes.")
        }
        guard let key: PowerAuthSecureVaultKey = register.touch(id: objectId) else {
            throw PluginException(.invalidNativeObject, message: "Secure Vault key object is no longer valid.")
        }
        let derivedKey = try key.deriveKey(withIndex: UInt64(index), keySize: UInt64(keySize))
        result(copySecureData(derivedKey))
    }
    
    private func requestAccessToken(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            let tokenName: String = try call.requireParameter(Args.tokenName)
            let auth = try constructAuthentication(call)
            sdk.tokenStore.requestAccessToken(withName: tokenName, authentication: auth) { token, error in
                wrap {
                    _ = auth
                    if let error {
                        throw error
                    }
                    guard let token else {
                        throw PluginException(.unknownError, message: "PowerAuth SDK returned neither an access token nor an error.")
                    }
                    result([
                        "tokenName": token.tokenName,
                        "tokenIdentifier": token.tokenIdentifier
                    ])
                }
            }
        }
    }
    
    private func removeAccessToken(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            let tokenName: String = try call.requireParameter(Args.tokenName)
            sdk.tokenStore.removeAccessToken(withName: tokenName) { removed, error in
                wrap {
                    if let error {
                        throw error
                    }
                    guard removed else {
                        throw PluginException(.unknownError, message: "PowerAuth SDK failed to remove the access token without returning an error.")
                    }
                    result(nil)
                }
            }
        }
    }
    
    private func hasLocalToken(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            let tokenName: String = try call.requireParameter(Args.tokenName)
            result(sdk.tokenStore.hasLocalToken(withName: tokenName))
        }
    }
    
    private func getLocalToken(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            let tokenName: String = try call.requireParameter(Args.tokenName)
            guard let token = sdk.tokenStore.localToken(withName: tokenName) else {
                throw PluginException(.localTokenNotAvailable, message: "Token with the name \(tokenName) is not in the local store.")
            }
            result([
                "tokenName": token.tokenName,
                "tokenIdentifier": token.tokenIdentifier
            ])
        }
    }
    
    private func removeLocalToken(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            let tokenName: String = try call.requireParameter(Args.tokenName)
            sdk.tokenStore.removeLocalToken(withName: tokenName)
            result(nil)
        }
    }
    
    private func removeAllLocalTokens(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            sdk.tokenStore.removeAllLocalTokens()
            result(nil)
        }
    }
    
    private func generateHeaderForToken(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            let tokenName: String = try call.requireParameter(Args.tokenName)
            sdk.tokenStore.generateAuthenticationHeader(withName: tokenName) { header, error in
                wrap {
                    if let error {
                        throw error
                    }
                    guard let header else {
                        throw PluginException(.unknownError, message: "PowerAuth SDK returned neither a token authentication header nor an error.")
                    }
                    result(header.serializable)
                }
            }
        }
    }
    
    private func fetchUserInfo(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            sdk.fetchUserInfo { userInfo, error in
                wrap {
                    if let error {
                        throw error
                    }
                    guard let userInfo else {
                        throw PluginException(.unknownError, message: "PowerAuth SDK returned neither user information nor an error.")
                    }
                    result(["allClaims": userInfo.allClaims])
                }
            }
        }
    }
    
    private func getLastFetchedUserInfo(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            if let userInfo = sdk.lastFetchedUserInfo {
                result(["allClaims": userInfo.allClaims])
            } else {
                result(nil)
            }
        }
    }
    
    private func isTimeSynchronized(_ call : FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            result(sdk.timeSynchronizationService.isTimeSynchronized)
        }
    }
    
    private func localTimeAdjustment(_ call : FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            result(sdk.timeSynchronizationService.localTimeAdjustment.milliseconds)
        }
    }
    
    private func localTimeAdjustmentPrecision(_ call : FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            result(sdk.timeSynchronizationService.localTimeAdjustmentPrecision.milliseconds)
        }
    }
    
    private func currentTime(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            // the native SDK returns time in seconds, but we need milliseconds
            result(sdk.timeSynchronizationService.currentTime().milliseconds)
        }
    }
    
    private func synchronizeTime(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            sdk.timeSynchronizationService.synchronizeTime( callback: { error in
                wrap {
                    if let error {
                        throw error
                    } else {
                        result(nil)
                    }
                }
            }, callbackQueue: nil)
        }
    }
    
    private func resetTimeSynchronization(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        try usePowerAuth(call, result) { sdk, wrap in
            sdk.timeSynchronizationService.resetTimeSynchronization()
            result(nil)
        }
    }
    
    // MARK: PowerAuth Helper methods
    
    private func usePowerAuth(_ call: FlutterMethodCall, _ result: @escaping FlutterResult, _ block: (PowerAuthSDK, @escaping WrapThrowBlock) throws -> Void) throws {
        try register.usePowerAuthSDK(id: try call.requireParameter(Args.instanceId), result, block)
    }
    
    private func usePassword(_ dict: FlutterMap?) throws -> PowerAuthPassword {
        return try register.usePassword(dict: dict)
    }
    
    /// Builds an authentication object that owns copies of credentials consumed from the register.
    ///
    /// Callers starting asynchronous native operations must capture the returned object until
    /// their callback finishes. This prevents password or biometric key material from being
    /// released while the native SDK still uses it.
    private func constructAuthentication(_ call: FlutterMethodCall) throws -> PowerAuthAuthentication {
        
        let dict: FlutterMap = try call.requireParameter(Args.authentication)
        let useBiometry = dict.get(Args.isBiometry, defaultValue: false)
        guard let persist: Bool = dict.get(Args.isPersist) else {
            throw PluginException(.wrongParameter, message: "Missing authentication purpose ('isPersist').")
        }
        
        let userPassword: FlutterMap? = dict.get(Args.password)
        
        if persist {
            // Activation persist
            let password = try usePassword(userPassword).copyToImmutable()
            if useBiometry {
                // All factors needs to be estabilished in activation.
                return PowerAuthAuthentication.persistWithPasswordAndBiometry(password: password)
            } else {
                return PowerAuthAuthentication.persistWithPassword(password: password)
            }
        } else {
            // Data signing
            if let userPassword {
                let password = try usePassword(userPassword).copyToImmutable()
                return PowerAuthAuthentication.possessionWithPassword(password: password)
            } else if useBiometry {
                guard let biometryKeyId = dict["biometryKeyId"] as? String else {
                    throw PluginException(.wrongParameter, message: "Biometric signing requires a pre-authorized biometry key.")
                }
                guard let biometryKeyData: PowerAuthSecureData = register.use(id: biometryKeyId) else {
                    throw PluginException(.invalidNativeObject, message: "Biometric key in PowerAuthAuthentication object is no longer valid.")
                }
                let ownedBiometryKey = PowerAuthSecureData(withData: biometryKeyData.sensitiveData)
                return PowerAuthAuthentication.possessionWithBiometry(customBiometryKey: ownedBiometryKey)
            } else {
                return PowerAuthAuthentication.possession()
            }
        }
    }
}

private func buildPowerAuthConfiguration(instanceId: String, arguments: FlutterMap) throws -> PowerAuthConfiguration {
    let sdkConfig: String = try arguments.require(PowerAuthService.Args.configuration)
    let baseEndpointUrl: String = try arguments.require(PowerAuthService.Args.baseEndpointUrl)
    let configuration: PowerAuthConfiguration
    if let algorithmValue: String = arguments.get(PowerAuthService.Args.algorithm) {
        configuration = PowerAuthConfiguration(
            instanceId: instanceId,
            baseEndpointUrl: baseEndpointUrl,
            configuration: sdkConfig,
            algorithm: try PowerAuthAlgorithm.from(serialized: algorithmValue)
        )
    } else {
        configuration = PowerAuthConfiguration(
            instanceId: instanceId,
            baseEndpointUrl: baseEndpointUrl,
            configuration: sdkConfig
        )
    }
    if let componentLength: Int = arguments.get(PowerAuthService.Args.offlineAuthenticationCodeComponentLength) {
        guard (4...8).contains(componentLength) else {
            throw PluginException(
                .wrongParameter,
                message: "Offline authentication code component length must be between 4 and 8."
            )
        }
        configuration.offlineAuthenticationCodeComponentLength = UInt(componentLength)
    }
    return configuration
}

private func applySharingConfiguration(
    _ arguments: FlutterMap?,
    to configuration: PowerAuthConfiguration
) throws {
    guard let arguments else {
        return
    }
    configuration.sharingConfiguration = PowerAuthSharingConfiguration(
        appGroup: try arguments.require(PowerAuthService.Args.appGroup),
        appIdentifier: try arguments.require(PowerAuthService.Args.appIdentifier),
        keychainAccessGroup: try arguments.require(PowerAuthService.Args.keychainAccessGroup)
    )
}

private extension PowerAuthConfiguration {
    func serializable() throws -> FlutterMap {
        return [
            PowerAuthService.Args.configuration.rawValue: configuration,
            PowerAuthService.Args.baseEndpointUrl.rawValue: baseEndpointUrl,
            PowerAuthService.Args.algorithm.rawValue: try algorithm.serializable,
            PowerAuthService.Args.offlineAuthenticationCodeComponentLength.rawValue: Int(offlineAuthenticationCodeComponentLength)
        ]
    }
}

private extension PowerAuthClientConfiguration {
    var serializable: FlutterMap {
        [
            PowerAuthService.Args.connectionTimeout.rawValue: defaultRequestTimeout,
            PowerAuthService.Args.defaultRequestTimeout.rawValue: defaultRequestTimeout,
            PowerAuthService.Args.enableUnsecureTraffic.rawValue: sslValidationStrategy is PowerAuthClientSslNoValidationStrategy
        ]
    }
}

private func copySecureData(_ secureData: PowerAuthSecureData) -> Data {
    return secureData.sensitiveData.withUnsafeBytes { Data($0) }
}

private extension TimeInterval {
    // TimeInterval is in seconds, but we need milliseconds for Flutter
    var milliseconds: Int { Int(self * 1000) }
}
