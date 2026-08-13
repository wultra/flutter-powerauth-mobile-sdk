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
import PowerAuth2

internal typealias WrapThrowBlock = (() throws -> Void) -> Void

internal typealias FlutterMap = [String: Any]

internal extension PowerAuthHttpHeader {
    var serializable: FlutterMap {
        [
            "name": key,
            "value": value
        ]
    }
}

internal extension FlutterMap {
    
    func get<T>(_ key: any RawRepresentable<String>) -> T? {
        return get(key.rawValue)
    }
    
    func get<T>(_ key: any RawRepresentable<String>, defaultValue: T) -> T {
        return get(key.rawValue) ?? defaultValue
    }
    
    func require<T>(_ key: any RawRepresentable<String>) throws -> T {
        return try require(key.rawValue)
    }
    
    fileprivate func get<T>(_ key: String) -> T? {
        return self[key] as? T
    }
    
    fileprivate func require<T>(_ key: String) throws -> T {
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

    func optionalDataParameter(_ key: any RawRepresentable<String>) -> Data? {
        let typedData: FlutterStandardTypedData? = getParameter(key)
        return typedData?.data
    }

    func requiredDataParameter(_ key: any RawRepresentable<String>) throws -> Data {
        let typedData: FlutterStandardTypedData = try requireParameter(key)
        return typedData.data
    }
    
    fileprivate func requireParameter<T>(_ key: String) throws -> T {
        guard let parameter: T = getParameter(key) else {
            throw PluginException(.wrongParameter, message: "Failed to retrieve required parameter \(key)")
        }
        return parameter
    }
    
    fileprivate func getParameter<T>(_ key: String) -> T? {
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

internal class PowerAuthData {
    
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
