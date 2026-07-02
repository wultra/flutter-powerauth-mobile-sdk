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

package com.wultra.android.powerauth.flutter.internal.utils

import com.wultra.android.powerauth.flutter.Errors
import com.wultra.android.powerauth.flutter.WrapperException
import io.getlime.security.powerauth.sdk.PowerAuthAlgorithm

object PowerAuthAlgorithmUtils {

    private const val ALGORITHM_LEGACY = "legacy"
    private const val ALGORITHM_P384 = "p384"
    private const val ALGORITHM_P384_L3 = "p384l3"
    private const val ALGORITHM_P384_L5 = "p384l5"

    @PowerAuthAlgorithm
    fun algorithmFromString(value: String): Int {
        return when (value) {
            ALGORITHM_LEGACY -> PowerAuthAlgorithm.LEGACY_P256
            ALGORITHM_P384 -> PowerAuthAlgorithm.EC_P384
            ALGORITHM_P384_L3 -> PowerAuthAlgorithm.EC_P384_ML_L3
            ALGORITHM_P384_L5 -> PowerAuthAlgorithm.EC_P384_ML_L5
            else -> throw WrapperException(
                Errors.EC_WRONG_PARAMETER,
                "Unknown PowerAuth algorithm: $value"
            )
        }
    }

    fun algorithmToString(@PowerAuthAlgorithm value: Int): String {
        return when (value) {
            PowerAuthAlgorithm.LEGACY_P256 -> ALGORITHM_LEGACY
            PowerAuthAlgorithm.EC_P384 -> ALGORITHM_P384
            PowerAuthAlgorithm.EC_P384_ML_L3 -> ALGORITHM_P384_L3
            PowerAuthAlgorithm.EC_P384_ML_L5 -> ALGORITHM_P384_L5
            else -> throw WrapperException(
                Errors.EC_WRONG_PARAMETER,
                "Unknown native PowerAuth algorithm: $value"
            )
        }
    }
}
