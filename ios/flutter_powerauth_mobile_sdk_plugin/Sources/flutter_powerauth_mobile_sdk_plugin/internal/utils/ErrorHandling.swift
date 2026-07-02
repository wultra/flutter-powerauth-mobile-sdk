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
import PowerAuth2

internal extension FlutterError {
    
    /// Translates native SDK and transport failures into the stable error codes exposed to Dart.
    ///
    /// REST failures preserve the response metadata shape used by the Android implementation so
    /// callers can handle server errors consistently on both platforms.
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
            errorCode = .from(paErrorCode)
            if let responseObject = error.powerAuthRestApiErrorResponse {
                let httpStatusCode = responseObject.httpStatusCode
                var errorDetails: FlutterMap = ["httpStatusCode": httpStatusCode]
                if let responseData = error.userInfo[PowerAuthErrorInfoKey_ResponseData] as? Data,
                   let responseBody = String(data: responseData, encoding: .utf8) {
                    errorDetails["responseBody"] = responseBody
                } else if let additionalInfo = error.userInfo[PowerAuthErrorInfoKey_AdditionalInfo],
                          JSONSerialization.isValidJSONObject(additionalInfo),
                          let jsonData = try? JSONSerialization.data(withJSONObject: additionalInfo),
                          let responseBody = String(data: jsonData, encoding: .utf8) {
                    errorDetails["responseBody"] = responseBody
                }
                if let serverResponseCode = responseObject.responseObject?.code {
                    errorDetails["serverResponseCode"] = serverResponseCode
                }
                if let serverResponseMessage = responseObject.responseObject?.message {
                    errorDetails["serverResponseMessage"] = serverResponseMessage
                }
                details = errorDetails
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
