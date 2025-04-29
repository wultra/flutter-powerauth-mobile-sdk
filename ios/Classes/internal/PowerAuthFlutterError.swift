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
import PowerAuth2

internal enum PowerAuthFlutterError: String {
    case networkError
    case signatureError
    case invalidActivationState
    case invalidActivationData
    case missingActivation
    case pendingActivation
    case operationCanceled
    case invalidToken
    case invalidEncryptor
    case encryptionError
    case wrongParameter
    case protocolUpgrade
    case pendingProtocolUpgrade
    case watchConnectivity
    case biometryCancel
    case biometryFallback
    case biometryFailed
    case biometryLockout
    case biometryNotAvailable
    case biometryNotSupported
    case biometryNotConfigured
    case biometryNotEnrolled
    case authenticationError
    case responseError
    case unknownError
    case reactNativeError
    case invalidActivationObject
    case invalidActivationCode
    case invalidCharacter
    case localTokenNotAvailable
    case cannotGenerateToken
    case instanceNotConfigured
    case invalidNativeObject
    case timeSynchronization
    case externalPendingOperation
    
    static func from(_ code: PowerAuthErrorCode) -> PowerAuthFlutterError {
        return switch (code) {
        case .networkError:   .networkError
        case .signatureError: .signatureError
        case .invalidActivationState: .invalidActivationState
        case .invalidActivationData: .invalidActivationData
        case .missingActivation: .missingActivation
        case .activationPending: .pendingActivation
        case .biometryCancel: .biometryCancel
        case .operationCancelled: .operationCanceled
        case .invalidActivationCode: .invalidActivationCode
        case .invalidToken: .invalidToken
        case .encryption: .encryptionError
        case .wrongParameter: .wrongParameter
        case .protocolUpgrade: .protocolUpgrade
        case .pendingProtocolUpgrade: .pendingProtocolUpgrade
        case .biometryNotAvailable: .biometryNotAvailable
        case .watchConnectivity: .watchConnectivity
        case .biometryFailed: .biometryFailed
        case .biometryFallback: .biometryFallback
        case .timeSynchronization: .timeSynchronization
        case .NA: .unknownError // TODO: other handling?
        case .externalPendingOperation: .externalPendingOperation
        @unknown default: .unknownError // TODO: additional handling, maybe pass it to the message?
        }
    }
}
