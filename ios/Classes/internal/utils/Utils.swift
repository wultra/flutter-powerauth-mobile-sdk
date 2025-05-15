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

internal typealias FlutterMap = [String: Any]

internal extension FlutterMap {
    
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
        var data = NSMutableData(length: count)!
        arc4random_buf(data.mutableBytes, data.length)
        return data.base64EncodedString()
    }
}
