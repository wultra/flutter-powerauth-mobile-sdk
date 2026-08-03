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

private enum PowerAuthAlgorithmUtils {

    static let algorithmLegacy = "legacy"
    static let algorithmP384 = "p384"
    static let algorithmP384L3 = "p384l3"
    static let algorithmP384L5 = "p384l5"
}

internal extension PowerAuthAlgorithm {

    static func from(serialized value: String) throws -> PowerAuthAlgorithm {
        switch value {
        case PowerAuthAlgorithmUtils.algorithmLegacy: return .LEGACY_P256
        case PowerAuthAlgorithmUtils.algorithmP384: return .EC_P384
        case PowerAuthAlgorithmUtils.algorithmP384L3: return .EC_P384_ML_L3
        case PowerAuthAlgorithmUtils.algorithmP384L5: return .EC_P384_ML_L5
        default:
            throw PluginException(.wrongParameter, message: "Unknown PowerAuth algorithm: \(value)")
        }
    }

    var serializable: String {
        get throws {
            switch self {
            case .LEGACY_P256: return PowerAuthAlgorithmUtils.algorithmLegacy
            case .EC_P384: return PowerAuthAlgorithmUtils.algorithmP384
            case .EC_P384_ML_L3: return PowerAuthAlgorithmUtils.algorithmP384L3
            case .EC_P384_ML_L5: return PowerAuthAlgorithmUtils.algorithmP384L5
            @unknown default:
                throw PluginException(.wrongParameter, message: "Unknown native PowerAuth algorithm: \(self)")
            }
        }
    }
}
