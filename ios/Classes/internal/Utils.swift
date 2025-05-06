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
import UIKit
import PowerAuth2
import PowerAuthCore

internal extension FlutterError {
    
    convenience init(thrownByPlugin: Error) {
        if let pe = thrownByPlugin as? PluginException {
            self.init(code: pe.code, message: pe.message, details: pe.details)
            return
        }
        
        var errorCode: PowerAuthFlutterError
        var message: String
        var details: Any? = thrownByPlugin.localizedDescription
        
        // all PowerAuth errors are NSErrors
        let error = thrownByPlugin as NSError
        message = error.localizedDescription
        // If powerAuthErrorCode is different than .NA, then it's PowerAuthDomain error.
        let paErrorCode = error.powerAuthErrorCode
        if paErrorCode != PowerAuthErrorCode.NA {
            // Handle PA error
            if let responseData = error.userInfo[PowerAuthErrorInfoKey_AdditionalInfo] as? FlutterMap {
                // Handle error response received from the server. In this case, we have to re-create the error in a nice-to-serialize manner
                let responseObject = error.userInfo[PowerAuthErrorDomain] as? PowerAuthRestApiErrorResponse
                let httpStatusCode = responseObject?.httpStatusCode
                if (httpStatusCode == 401) {
                    errorCode = .authenticationError
                    message = "Unauthorized"
                } else {
                    errorCode = .responseError
                    message = "Wrong HTTP status code received from the server"
                }
                var newUserInfo: FlutterMap = [NSLocalizedDescriptionKey: message]
                if let responseObject {
                    newUserInfo["httpStatusCode"] = httpStatusCode
                    // Serialize dictionary back to string, to be compatible with Android
                    if let jsonData = try? JSONSerialization.data(withJSONObject: responseData as Any) {
                        if let jsonString = String(data: jsonData, encoding: .utf8) {
                            newUserInfo["responseBody"] = jsonString
                        }
                    }
                    if let serverResponseCode = responseObject.responseObject.code {
                        newUserInfo["serverResponseCode"] = serverResponseCode
                    }
                    if let serverResponseMessage = responseObject.responseObject.message {
                        newUserInfo["serverResponseMessage"] = serverResponseMessage
                    }
                }
                // Finally, build a new error
                details = [
                    "domain": PowerAuthErrorDomain,
                    "code": error.code,
                    "userInfo": newUserInfo
                ]
                //
            } else {
                // Other type of PowerAuthError. Just translate errorCode to string and keep NSError as it is.
                errorCode = .from(paErrorCode)
                //
            }
        } else if error.domain  == NSURLErrorDomain {
            // Handle error from NSURLSession
            errorCode = .networkError
            //
        } else {
            // We don't know this domain, so translate result as an UNKNOWN_ERROR
            errorCode = .unknownError
            //
        }
        
        // creat the code...
        self.init(code: errorCode, message: message, details: details)
    }
    
    private convenience init(code: PowerAuthFlutterError, message: String?, details: Any?) {
        self.init(code: code.rawValue, message: message, details: details)
    }
    
}

internal struct PluginException: Error {
    
    let code: PowerAuthFlutterError
    let message: String?
    let details: Any?
    
    init(_ code: PowerAuthFlutterError, message: String? = nil, details: Any? = nil) {
        self.code = code
        self.message = message
        self.details = details
    }
}

internal typealias FlutterMap = [String: Any]

internal extension FlutterMap {
    
    func get<T>(_ key: String) -> T? {
        return self[key] as? T
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

internal class Lock {
    
    /// Underlying synchronization primitive.
    private let semaphore: DispatchSemaphore
    
    /// Designated initializer
    init() {
        semaphore = DispatchSemaphore(value: 1)
    }
    
    /// Attempts to acquire a lock, blocking a thread’s execution
    /// until the lock can be acquired.
    func lock() {
        semaphore.wait()
    }
    
    /// Releases a previously acquired lock.
    func unlock() {
        semaphore.signal()
    }
    
    /// Executes block after lock is acquired and releases it immediately afterwards.
    /// - Parameter block: block that will be executed during the lock
    /// - Returns: returns the output pf the block
    func synchronized<T>(_ block: () -> T) -> T {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        return block()
    }
}

class Utils {
    
}
