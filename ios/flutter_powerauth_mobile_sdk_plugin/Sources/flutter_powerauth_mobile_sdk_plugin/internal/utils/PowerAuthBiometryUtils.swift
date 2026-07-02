/*
 * Copyright 2026 Wultra s.r.o.
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
import LocalAuthentication

internal enum PowerAuthBiometryUtils {

    static func authenticationContext(from prompt: FlutterMap?) throws -> LAContext {
        guard
            let promptMessage = prompt?["promptMessage"] as? String,
            !promptMessage.isEmpty
        else {
            throw PluginException(
                .wrongParameter,
                message: "Missing 'promptMessage' in prompt parameter"
            )
        }

        let context = LAContext()
        context.localizedReason = promptMessage
        context.localizedCancelTitle = prompt?["cancelButtonTitle"] as? String
        // An empty title hides the fallback button.
        context.localizedFallbackTitle = prompt?["fallbackButtonTitle"] as? String ?? ""
        return context
    }
}

internal extension PowerAuthBiometricStatus {

    var serializable: FlutterMap {
        let status = switch systemStatus {
        case .available: "ok"
        case .notSupported: "notSupported"
        case .notEnrolled: "notEnrolled"
        case .notAvailable: "notAvailable"
        case .lockout: "lockout"
        @unknown default: "notAvailable"
        }
        let type = switch biometryType {
        case .touchID: "fingerprint"
        case .faceID: "face"
        case .none: "none"
        @unknown default: "none"
        }
        return [
            "isAuthenticationWithBiometricsAvailable": isAuthenticationWithBiometricsAvailable,
            "isBiometricFactorConfigured": isBiometricFactorConfigured,
            "systemStatus": status,
            "biometryType": type
        ]
    }
}
