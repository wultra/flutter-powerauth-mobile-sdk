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

package com.wultra.android.powerauth.flutter.internal.utils

import io.getlime.security.powerauth.networking.response.CreateActivationResult
import io.getlime.security.powerauth.sdk.PowerAuthActivationState
import io.getlime.security.powerauth.sdk.PowerAuthActivationStatus
import io.getlime.security.powerauth.sdk.PowerAuthHttpHeader

object PowerAuthActivationUtils {
    fun activationStatusToMap(status: PowerAuthActivationStatus): Map<String, Any?> {
        return mapOf(
            "state" to activationStateToString(status.state),
            "failCount" to status.failCount,
            "maxFailCount" to status.maxFailCount,
            "remainingAttempts" to status.remainingAttempts,
            "customObject" to status.customObject
        )
    }

    fun createActivationResultToMap(activationResult: CreateActivationResult): Map<String, Any?> {
        return mapOf(
            "activationFingerprint" to activationResult.activationFingerprint,
            "customAttributes" to activationResult.customActivationAttributes,
            "userInfoClaims" to activationResult.userInfo?.allClaims
        )
    }

    fun authorizationHeaderToMap(header: PowerAuthHttpHeader): Map<String, String> {
//        if (header.powerAuthErrorCode != PowerAuthErrorCodes.SUCCEED) {
//            throw PowerAuthErrorException(header.powerAuthErrorCode)
//        }

        return mapOf(
            "key" to header.key,
            "value" to header.value
        )
    }

    private fun activationStateToString(state: Int): String {
        return when (state) {
            PowerAuthActivationState.PENDING_COMMIT -> "pendingCommit"
            PowerAuthActivationState.ACTIVE -> "active"
            PowerAuthActivationState.BLOCKED -> "blocked"
            PowerAuthActivationState.REMOVED -> "removed"
            PowerAuthActivationState.DEADLOCK -> "deadlock"
            else -> "unknown"
        }
    }
}
