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
        "encryptor_canEncryptRequest": canEncryptRequest,
        "encryptor_encryptRequest": encryptRequest,
        "encryptor_canDecryptResponse": canDecryptResponse,
        "encryptor_decryptResponse": decryptResponse,
    ]
    
    fileprivate enum Args: String {
        case scope
        case powerAuthInstanceId
        case objectId
        case requestBody
        case responseBody
    }
    
    private func initialize(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        let scope: String = try call.requireParameter(Args.scope)
        let instanceId: String = try call.requireParameter(Args.powerAuthInstanceId)
        let sdk = try register.requirePowerAuthSDK(id: instanceId)

        let callback: (PowerAuthEncryptor?, Error?) -> Void = { encryptor, error in
            Utils.wrapThrowBlock(result: result) {
                if let error {
                    throw error
                }
                guard let encryptor else {
                    throw PluginException(.unknownError, message: "PowerAuth SDK returned neither an encryptor nor an error.")
                }
                guard let objectId = self.register.add(
                    object: encryptor,
                    ifOwnerMatches: sdk,
                    ownerId: instanceId,
                    policies: [.keepAlive(Constants.ENCRYPTOR_KEEP_ALIVE_TIME)]
                ) else {
                    throw PluginException(.instanceNotConfigured, message: "PowerAuth instance is no longer configured.")
                }
                result(objectId)
            }
        }

        switch scope {
        case "application":
            _ = sdk.encryptorForApplicationScope(callback: callback)
        case "activation":
            _ = sdk.encryptorForActivationScope(callback: callback)
        default:
            throw PluginException(.wrongParameter, message: "Unknown scope value: \(scope)")
        }
    }
    
    private func canEncryptRequest(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        result(try encryptor(call, touch: true).canEncryptRequest)
    }
    
    private func encryptRequest(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        let encryptor = try encryptor(call, touch: true)
        let requestBody = call.optionalDataParameter(Args.requestBody)
        let encryptedRequest = try encryptor.encryptRequest(requestBody)
        result([
            "requestBody": Data(encryptedRequest.requestBody),
            "requestHeaders": encryptedRequest.requestHeaders.map(\.serializable)
        ])
    }
    
    private func canDecryptResponse(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        result(try encryptor(call, touch: true).canDecryptResponse)
    }
    
    private func decryptResponse(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        let objectId: String = try call.requireParameter(Args.objectId)
        defer {
            register.removeAny(id: objectId)
        }
        guard let encryptor: PowerAuthEncryptor = register.touch(id: objectId) else {
            throw PluginException(.invalidNativeObject, message: "Encryptor object is no longer valid.")
        }
        let responseBody = try call.requiredDataParameter(Args.responseBody)
        let encryptedResponse = try PowerAuthEncryptedResponse(responseBody: responseBody)
        result(try encryptor.decryptResponse(encryptedResponse))
    }
    
    private func encryptor(_ call: FlutterMethodCall, touch: Bool) throws -> PowerAuthEncryptor {
        let objectId: String = try call.requireParameter(Args.objectId)
        let encryptor: PowerAuthEncryptor? = touch
            ? register.touch(id: objectId)
            : register.find(id: objectId)
        guard let encryptor else {
            throw PluginException(.invalidNativeObject, message: "Encryptor object is no longer valid.")
        }
        return encryptor
    }
}
