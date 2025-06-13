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

import io.getlime.security.powerauth.core.ActivationStatus
import io.getlime.security.powerauth.exception.PowerAuthErrorCodes
import io.getlime.security.powerauth.exception.PowerAuthErrorException
import io.getlime.security.powerauth.networking.response.CreateActivationResult
import io.getlime.security.powerauth.sdk.PowerAuthAuthorizationHttpHeader

object PowerAuthActivationUtils {
    fun activationStatusToMap(status: ActivationStatus): Map<String, Any?> {
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

    fun authorizationHeaderToMap(header: PowerAuthAuthorizationHttpHeader): Map<String, String> {
        if (header.powerAuthErrorCode != PowerAuthErrorCodes.SUCCEED) {
            throw PowerAuthErrorException(header.powerAuthErrorCode)
        }

        return mapOf(
            "key" to header.key,
            "value" to header.value
        )
    }

    private fun activationStateToString(state: Int): String {
        return when (state) {
            ActivationStatus.State_Created -> "created"
            ActivationStatus.State_Pending_Commit -> "pendingCommit"
            ActivationStatus.State_Active -> "active"
            ActivationStatus.State_Blocked -> "blocked"
            ActivationStatus.State_Removed -> "removed"
            ActivationStatus.State_Deadlock -> "deadlock"
            else -> "unknown"
        }
    }
}
