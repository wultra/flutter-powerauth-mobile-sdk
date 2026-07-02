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
        "util_correctTypedCharacter": correctTypedCharacter,
        "util_getEnvironmentInfo": getEnvironmentInfo,
        "util_migrateSharingConfiguration": migrateSharingConfiguration
    ]
    
    fileprivate enum Args: String {
        case character
        case activationCode
        case fromAppGroup
        case toAppGroup
    }
    
    private func validateActivationCode(_ call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        let code: String = try call.requireParameter(Args.activationCode)
        result(PowerAuthActivationCodeUtil.validateActivationCode(code))
    }
    
    private func parseActivationCode(_ call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        let code: String = try call.requireParameter(Args.activationCode)
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
        let char: Int = try call.requireParameter(Args.character)
        result(PowerAuthActivationCodeUtil.validateTypedCharacter(UInt32(char)))
    }
    
    private func correctTypedCharacter(_ call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        let char: Int = try call.requireParameter(Args.character)
        let validated = PowerAuthActivationCodeUtil.validateAndCorrectTypedCharacter(UInt32(char))
        result(validated)
    }

    private func getEnvironmentInfo(_ call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        let currentDevice = UIDevice.current
        let mainBundle = Bundle.main
        let mainDictionary = mainBundle.infoDictionary
        let appVersion = mainDictionary?["CFBundleShortVersionString"] as? String
        let appId = mainDictionary?["CFBundleIdentifier"] as? String
        
        result([
            "systemName": currentDevice.systemName,
            "systemVersion": currentDevice.systemVersion,
            
            "applicationVersion": appVersion,
            "applicationIdentifier": appId,
            
            "deviceManufacturer": "apple",
            "deviceId": currentDevice.model
        ])
    }

    /// Migrates the keychain initialization flag (`PowerAuthKeychain_Initialized`) between two
    /// `UserDefaults` suites identified by their app group names.
    ///
    /// This mirrors the migration described in the PowerAuth SDK for iOS Extensions documentation,
    /// but resolves the `UserDefaults` suite directly from the provided app group instead of the
    /// keychain configuration's `keychainAttribute_UserDefaultsSuiteName`. A `nil` app group
    /// resolves to the standard (non-shared) `UserDefaults`.
    ///
    /// See: https://developers.wultra.com/components/powerauth-mobile-sdk/1.9.x/documentation/PowerAuth-SDK-for-iOS-Extensions#userdefaults-migration
    private func migrateSharingConfiguration(_ call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        let fromAppGroup: String? = call.getParameter(Args.fromAppGroup)
        let toAppGroup: String? = call.getParameter(Args.toAppGroup)

        // Resolve the source and destination UserDefaults. A nil app group means the standard,
        // non-shared UserDefaults; a non-nil app group means the shared suite for that group.
        guard let from = userDefaults(forAppGroup: fromAppGroup),
              let to = userDefaults(forAppGroup: toAppGroup) else {
            // One of the suites could not be opened - data sharing is probably not configured properly.
            throw PluginException(.wrongParameter, message: "Failed to open UserDefaults for the provided app group. Data sharing is probably not configured properly.")
        }

        // If the destination is already initialized, the migration is not required.
        if to.bool(forKey: PowerAuthKeychain_Initialized) {
            result(nil)
            return
        }

        // Move the flag from the source suite to the destination suite.
        if from.bool(forKey: PowerAuthKeychain_Initialized) {
            from.removeObject(forKey: PowerAuthKeychain_Initialized)
            from.synchronize()
            to.set(true, forKey: PowerAuthKeychain_Initialized)
            to.synchronize()
        }

        result(nil)
    }

    /// Returns the `UserDefaults` for the given app group, or the standard `UserDefaults` when
    /// [appGroup] is `nil`. Returns `nil` when a shared suite for the given app group cannot be opened.
    private func userDefaults(forAppGroup appGroup: String?) -> UserDefaults? {
        guard let appGroup else {
            return .standard
        }
        return UserDefaults(suiteName: appGroup)
    }
}
