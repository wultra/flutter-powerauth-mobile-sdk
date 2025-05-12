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

internal class PowerAuthUtilsService: PowerAuthFlutterService {
    
    typealias Service = PowerAuthUtilsService
    
    // MARK: - PowerAuthFlutterService members
    
    var name: String { "PowerAuthUtils" }
    
    let handlers = [
        "util_parseActivationCode": parseActivationCode,
        "util_validateActivationCode": validateActivationCode,
        "util_validateTypedCharacter": validateTypedCharacter,
        "util_correctTypedCharacter": correctTypedCharacter
    ]
    
    fileprivate enum Args: String {
        case character
        case activationCode
    }
    
    private func validateActivationCode(_ call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        let code: String = try call.requireParameter(.activationCode)
        result(PowerAuthActivationCodeUtil.validateActivationCode(code))
    }
    
    private func parseActivationCode(_ call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        let code: String = try call.requireParameter(.activationCode)
        if let parsed = PowerAuthActivationCodeUtil.parse(fromActivationCode: code) {
            result([
                "activationCode": parsed.activationCode,
                "activationSignature": parsed.activationSignature
            ])
        } else {
            throw PluginException(.invalidActivationCode, message: "Invalid activation code.")
        }
    }
    
    private func validateTypedCharacter(_ call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        let char: Int = try call.requireParameter(.character)
        result(PowerAuthActivationCodeUtil.validateTypedCharacter(UInt32(char)))
    }
    
    private func correctTypedCharacter(_ call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        let char: Int = try call.requireParameter(.character)
        let validated = PowerAuthActivationCodeUtil.validateAndCorrectTypedCharacter(UInt32(char))
        result(validated)
    }
}

private extension FlutterMethodCall {
    func requireParameter<T>(_ key: PowerAuthUtilsService.Args) throws -> T {
        return try requireParameter(key.rawValue)
    }
    
    func getParameter<T>(_ key: PowerAuthUtilsService.Args) -> T? {
        return getParameter(key.rawValue)
    }
}
