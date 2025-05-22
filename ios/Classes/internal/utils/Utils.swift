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

import Foundation
import Flutter

internal typealias WrapThrowBlock = (() throws -> Void) -> Void

internal typealias FlutterMap = [String: Any]

internal extension FlutterMap {
    
    func get<T>(_ key: any RawRepresentable<String>) -> T? {
        return get(key.rawValue)
    }
    
    func get<T>(_ key: String) -> T? {
        return self[key] as? T
    }
    
    func require<T>(_ key: String) throws -> T {
        guard let parameter: T = get(key) else {
            throw PluginException(.wrongParameter, message: "Failed to retrieve required parameter \(key)")
        }
        return parameter
    }
}

internal extension FlutterMethodCall {
    
    func requireParameter<T>(_ key: any RawRepresentable<String>) throws -> T {
        return try requireParameter(key.rawValue)
    }
    
    func getParameter<T>(_ key: any RawRepresentable<String>) -> T? {
        getParameter(key.rawValue)
    }
    
    func requireParameter<T>(_ key: String) throws -> T {
        guard let parameter: T = getParameter(key) else {
            throw PluginException(.wrongParameter, message: "Failed to retrieve required parameter \(key)")
        }
        return parameter
    }
    
    func getParameter<T>(_ key: String) -> T? {
        guard let arguments = arguments as? FlutterMap else {
            return nil
        }
        
        return arguments.get(key)
    }
}

internal class Utils {
    static func getRandomString() -> String {
        let count = Int(3 * (3 + arc4random_uniform(6)))
        let data = NSMutableData(length: count)!
        arc4random_buf(data.mutableBytes, data.length)
        return data.base64EncodedString()
    }
    
    /// Wraps a throw block. If exception is thrown, it properly calls the `result` with an error.
    static func wrapThrowBlock(result: @escaping FlutterResult, _ block: () throws -> Void) {
        do {
            try block()
        } catch let e {
            result(FlutterError(thrownByPlugin: e))
        }
    }
}

internal enum PowerAuthDataFormat: String {
    case UTF8
    case BASE64
    
    static func fromString(_ string: String?) throws -> PowerAuthDataFormat {
        
        guard let string else {
            return .UTF8
        }
        
        guard let format =  PowerAuthDataFormat(rawValue: string) else {
            throw PluginException(.wrongParameter, message: "Unsupported data format '\(string)'")
        }
        
        return format
    }
}

internal extension Data {
    
    static func decodeDataValue(_ dataValue: String, format: PowerAuthDataFormat) throws -> Data {
        switch format {
        case .UTF8:
            guard let data = dataValue.data(using: .utf8) else {
                throw PluginException(.wrongParameter, message: "Failed to decode data value using UTF-8 format")
            }
            return data
        case .BASE64:
            guard let data = Data(base64Encoded: dataValue) else {
                throw PluginException(.wrongParameter, message: "Failed to decode data value using BASE64 format")
            }
            return data
        }
    }
    
    static func encodeDataValue(_ dataValue: Data, format: PowerAuthDataFormat) throws -> String {
        switch format {
        case .UTF8:
            guard let value = String(data: dataValue, encoding: .utf8) else {
                throw PluginException(.unknownError, message: "Failed to create string from UTF-8 encoded data")
            }
            return value
        case .BASE64:
            return dataValue.base64EncodedString()
        }
    }
}
