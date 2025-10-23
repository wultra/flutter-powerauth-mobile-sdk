/*
 * Copyright 2025 Wultra s.r.o.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation
import Flutter
import PowerAuthCore

internal class PowerAuthCoreCryptoUtilsService: PowerAuthFlutterService {
    
    // MARK: - PowerAuthFlutterService members
    
    let name = "PowerAuthCoreCryptoUtils"
    
    let handlers = [
        "cryptoUtils_randomBytes": randomBytes,
        "cryptoUtils_hashSha256": hashSha256
    ]
    
    fileprivate enum Args: String {
        case length
        case data
        case dataFormat
        case outputDataFormat
    }
    
    // MARK: - Handlers
    
    private func randomBytes(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        let length: Int = try call.requireParameter(Args.length)
        guard length >= 0 else {
            throw PluginException(.wrongParameter, message: "Length must be non-negative")
        }
        
        // Generate random bytes using PowerAuthCore
        let bytes = PowerAuthCoreCryptoUtils.randomBytes(UInt(length)) ?? Data()
        result(bytes)
    }
    
    private func hashSha256(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
        do {
                guard let args = call.arguments as? [String: Any],
                      let typedData = args[Args.data.rawValue] as? FlutterStandardTypedData else {
                    throw FlutterError(code: "INVALID_ARGUMENT", message: "Missing or invalid 'data' parameter", details: nil) as! any Error
                }
                
                let dataValue = typedData.data  // This is Swift Data
                let digest = PowerAuthCoreCryptoUtils.hashSha256(dataValue)
                
                result(digest)
            } catch {
                result(FlutterError(code: "HASH_ERROR", message: error.localizedDescription, details: nil))
            }
    }
}
