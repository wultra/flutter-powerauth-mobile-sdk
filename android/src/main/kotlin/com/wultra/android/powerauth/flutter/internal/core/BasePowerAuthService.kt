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

package com.wultra.android.powerauth.flutter.internal.core

import android.os.Handler
import android.os.Looper
import com.wultra.android.powerauth.flutter.Errors
import com.wultra.android.powerauth.flutter.PowerAuthObjectRegister
import com.wultra.android.powerauth.flutter.WrapperException
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import io.getlime.security.powerauth.sdk.PowerAuthSDK

abstract class BasePowerAuthService(
    private val register: PowerAuthObjectRegister?
) : PowerAuthFlutterService {

    companion object ArgKeys {
        const val INSTANCE_ID = "instanceId"
    }

    protected fun usePowerAuth(
        call: MethodCall,
        result: Result,
        block: (PowerAuthSDK) -> Unit
    ) {
        try {
            val instanceId: String = call.getRequiredArgument(INSTANCE_ID)
            val sdkForBlock = register?.useObject(instanceId, PowerAuthSDK::class.java)
                ?: throw WrapperException(
                    Errors.EC_INSTANCE_NOT_CONFIGURED,
                    "PowerAuth instance '$instanceId' not configured or no longer valid."
                )

            block(sdkForBlock)
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    protected fun usePowerAuthOnMainThread(
        call: MethodCall,
        result: Result,
        block: (sdk: PowerAuthSDK) -> Unit
    ) {
        Handler(Looper.getMainLooper()).post {
            usePowerAuth(call, result) { sdk ->
                block(sdk)
            }
        }
    }

    @Throws(WrapperException::class)
    fun <T> MethodCall.getRequiredArgument(key: String): T {
        return this.argument<T>(key) ?: throw WrapperException(
            Errors.EC_WRONG_PARAMETER,
            "Missing required argument: '$key'"
        )
    }

    override fun cleanUp() {
        // Default implementation does nothing, but can be overridden by services that need to clean up.
    }
}
