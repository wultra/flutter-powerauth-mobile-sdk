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
import PowerAuth2
import Flutter
import Foundation

class PowerAuthEncryptorService: PowerAuthFlutterService {
    
    let name = "PowerAuthEncryptorService"
    private let register: PowerAuthObjectRegister
    
    init(register: PowerAuthObjectRegister) {
        self.register = register
    }
    
    let handlers = [
        "encryptor_initialize": initialize,
        "encryptor_release": release,
        "encryptor_canEncryptRequest": canEncryptRequest,
        "encryptor_encryptRequest": encryptRequest,
        "encryptor_canDecryptResponse": canDecryptResponse,
        "encryptor_decryptResponse": decryptResponse,
    ]
    
    fileprivate enum Args: String {
        case scope
        case ownerId
        case autoreleaseTime
        case encryptorId
        case body
        case bodyFormat
        case data
        case cryptogram
        case outputFormat
    }
    
    // MARK: - Handlers
    
    private func initialize(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        
        let scope: String = try call.requireParameter(.scope)
        let ownerId: String = try call.requireParameter(.ownerId)
        let autoreleaseTime: Int = try call.requireParameter(.autoreleaseTime)
        
        let isActivationScope: Bool
        if scope == "APPLICATION" {
            isActivationScope = false
        } else if scope == "ACTIVATION" {
            isActivationScope = true
        } else {
            throw PluginException(.wrongParameter, message: "Unknown scope value: \(scope)")
        }
        
        try register.usePowerAuthSDK(id: ownerId, result) { sdk, wrap in
            
            let encryptorFactory = isActivationScope ? sdk.eciesEncryptorForActivationScope : sdk.eciesEncryptorForApplicationScope
            
            _ = encryptorFactory { coreEncryptor, error in
                wrap {
                    guard let coreEncryptor else {
                        if isActivationScope && sdk.hasValidActivation() == false {
                            throw PluginException(.missingActivation)
                        }
                        throw error ?? PluginException(.unknownError, message: "Failed to create ECIES encryptor")
                    }
                    
                    let encryptor = PowerAuthFlutterEncryptor(activationScoped: isActivationScope, coreEncryptor: coreEncryptor, powerAuthInstanceId: ownerId)
                    let encryptorId = self.register.add(
                        object: encryptor,
                        tag: ownerId,
                        policies: [.keepAlive(ReleasePolicy.getTimeInterval(value: autoreleaseTime, defaultValue: Constants.ENCRYPTOR_KEEP_ALIVE_TIME))]
                    )
                    result(encryptorId)
                }
            }
        }
    }
    
    private func release(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        register.remove(id: try call.requireParameter(.encryptorId))
        result(nil)
    }
    
    private func canEncryptRequest(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        let id: String = try call.requireParameter(.encryptorId)
        let encryptor = try touchEcryptor(id: id)
        result(register.canEncrypt(with: encryptor) == .success)
    }
    
    private func encryptRequest(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        
        let encryptorId: String = try call.requireParameter(.encryptorId)
        let body: String = try call.requireParameter(.body)
        let bodyFormat: String = try call.requireParameter(.bodyFormat)
        
        let encryptor = try useEcryptor(id: encryptorId)
        
        let bodyDataFormat = try PowerAuthDataFormat.fromString(bodyFormat)
        let data = try Data.decodeDataValue(body, format: bodyDataFormat)
        
        let canEncrypt = register.canEncrypt(with: encryptor)
        
        if canEncrypt != .success {
            // Remove object from the register if decryption is no longer available.
            register.remove(id: encryptorId)
        }
        
        switch canEncrypt {
        case .invalidEncryptor: throw PluginException(.invalidEncryptor, message: "Encryptor is not constructed for request encryption")
        case .missingActivation: throw PluginException(.missingActivation)
        case .missingSdk: throw PluginException(.instanceNotConfigured)
        case .success: break
        }
        
        encryptor.coreEncryptor.encryptRequest(data) { cryptogram, decryptor in
            Utils.wrapThrowBlock(result: result) {
                guard let cryptogram, let decryptor else {
                    throw PluginException(.encryptionError, message: "Failed to encrypt request")
                }
                
                guard let metadata = decryptor.associatedMetaData else {
                    // PA_SDK behavior has been changed...
                    throw PluginException(.invalidEncryptor, message: "Incompatible native SDK")
                }
                
                // Wrap decryptor and register it in the object register
                let ftDecryptor = PowerAuthFlutterEncryptor(
                    activationScoped: encryptor.activationScoped,
                    coreEncryptor: decryptor,
                    powerAuthInstanceId: encryptor.powerAuthInstanceId
                )
                let decryptorId = self.register.add(
                    object: ftDecryptor,
                    tag: encryptor.powerAuthInstanceId,
                    policies: [.afterUse(1), .expire(Constants.DECRYPTOR_KEEP_ALIVE_TIME)]
                )
                result([
                    "cryptogram": [
                        "ephemeralPublicKey": cryptogram.keyBase64,
                        "encryptedData": cryptogram.bodyBase64,
                        "mac": cryptogram.macBase64,
                        "nonce": cryptogram.nonceBase64
                    ],
                    "header": [
                        "key": metadata.httpHeaderKey,
                        "value": metadata.httpHeaderValue
                    ],
                    "decryptorId": decryptorId
                ])
            }
        }
    }
    
    private func canDecryptResponse(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        let id: String = try call.requireParameter(.encryptorId)
        let encryptor = try touchEcryptor(id: id)
        result(register.canDecrypt(with: encryptor) == .success)
    }
    
    private func decryptResponse(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        let encryptorId: String = try call.requireParameter(.encryptorId)
        let cryptogramDict: FlutterMap = try call.requireParameter(.cryptogram)
        let outputFormat: String = try call.requireParameter(.outputFormat)
        
        let encryptor = try useEcryptor(id: encryptorId)
        
        let dataFormat = try PowerAuthDataFormat.fromString(outputFormat)
        
        let canEncrypt = register.canDecrypt(with: encryptor)
        
        if canEncrypt != .success {
            // Remove object from the register if decryption is no longer available.
            register.remove(id: encryptorId)
        }
        
        switch canEncrypt {
        case .invalidEncryptor: throw PluginException(.invalidEncryptor, message: "Encryptor is not constructed for request encryption")
        case .missingActivation: throw PluginException(.missingActivation)
        case .missingSdk: throw PluginException(.instanceNotConfigured)
        case .success: break
        }
        
        // decrypt
        guard let cryptogram = PowerAuthCoreEciesCryptogram(responsePayload: cryptogramDict) else {
            throw PluginException(.encryptionError, message: "Failed to create cryptogram")
        }
        
        guard let response = encryptor.coreEncryptor.decryptResponse(cryptogram) else {
            throw PluginException(.encryptionError, message: "Failed to decrypt response")
        }
        
        result(try Data.encodeDataValue(response, format: dataFormat))
    }
    
    // MARK: - Helpers
    
    private func getEcryptor(id: String, touch: Bool) throws -> PowerAuthFlutterEncryptor {
        guard let encrytor: PowerAuthFlutterEncryptor = touch ? register.touch(id: id) : register.use(id: id) else {
            throw PluginException(.invalidNativeObject, message: "Encryptor object is no longer valid")
        }
        return encrytor
    }
    
    private func useEcryptor(id: String) throws -> PowerAuthFlutterEncryptor {
        return try getEcryptor(id: id, touch: false)
    }
    
    private func touchEcryptor(id: String) throws -> PowerAuthFlutterEncryptor {
        return try getEcryptor(id: id, touch: true)
    }
}

/// Object containing all encryptor's data required for the request encryption.
private class PowerAuthFlutterEncryptor {
    let activationScoped: Bool
    let coreEncryptor: PowerAuthCoreEciesEncryptor
    let powerAuthInstanceId: String
    
    init(activationScoped: Bool, coreEncryptor: PowerAuthCoreEciesEncryptor, powerAuthInstanceId: String) {
        self.activationScoped = activationScoped
        self.coreEncryptor = coreEncryptor
        self.powerAuthInstanceId = powerAuthInstanceId
    }
}

private enum CanCryptResult {
    case success
    case invalidEncryptor
    case missingActivation
    case missingSdk
}

private extension PowerAuthObjectRegister {
    
    /// Determine whether encryptor is able to encrypt the request data. The function also validate state of PowerAuthSDK if
    /// encryptor is configured for an activation scope.
    /// - Parameters:
    ///   - encryptor: Encryptor container
    func canEncrypt(with encryptor: PowerAuthFlutterEncryptor) -> CanCryptResult {
        guard let sdk = getPowerAuthSDK(id: encryptor.powerAuthInstanceId) else {
            return .missingSdk
        }
        guard encryptor.activationScoped == false || sdk.hasValidActivation() else {
            return .missingActivation
        }
        return encryptor.coreEncryptor.canEncryptRequest ? .success : .invalidEncryptor
    }
    
    /// Determine whether encryptor is able to decrypt the response cryptogram. The function also validate state of PowerAuthSDK if
    /// encryptor is configured for an activation scope.
    /// - Parameters:
    ///   - encryptor: Encryptor container
    func canDecrypt(with encryptor: PowerAuthFlutterEncryptor) -> CanCryptResult {
        guard let sdk = getPowerAuthSDK(id: encryptor.powerAuthInstanceId) else {
            return .missingSdk
        }
        guard encryptor.activationScoped == false || sdk.hasValidActivation() else {
            return .missingActivation
        }
        return encryptor.coreEncryptor.canDecryptResponse ? .success : .invalidEncryptor
    }
}

private extension FlutterMethodCall {
    func requireParameter<T>(_ key: PowerAuthEncryptorService.Args) throws -> T {
        return try requireParameter(key.rawValue)
    }
    
    func getParameter<T>(_ key: PowerAuthEncryptorService.Args) -> T? {
        return getParameter(key.rawValue)
    }
}
