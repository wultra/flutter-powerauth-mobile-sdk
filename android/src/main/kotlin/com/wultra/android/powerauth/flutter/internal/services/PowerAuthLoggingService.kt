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
package com.wultra.android.powerauth.flutter.internal.services

import com.wultra.android.powerauth.flutter.Errors
import com.wultra.android.powerauth.flutter.internal.utils.PowerAuthLogger
import com.wultra.android.powerauth.flutter.internal.utils.PowerAuthLogLevel
import com.wultra.android.powerauth.flutter.internal.core.BasePowerAuthService
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result

class PowerAuthLoggingService : BasePowerAuthService(null) {

    override val name = "logging"

    private companion object ArgKeys {
        const val LEVEL = "level"
        const val ENABLED = "enabled"
    }

    private object HandlerNames {
        const val SET_NATIVE_LOG_LEVEL = "setNativeLogLevel"
        const val SET_NATIVE_LOGGING_ENABLED = "setNativeLoggingEnabled"
    }

    override val handlers by lazy {
        mapOf(
            HandlerNames.SET_NATIVE_LOG_LEVEL to this::setNativeLogLevel,
            HandlerNames.SET_NATIVE_LOGGING_ENABLED to this::setNativeLoggingEnabled
        )
    }

    private fun setNativeLogLevel(call: MethodCall, result: Result) {
        val levelString = call.getRequiredArgument<String>(LEVEL).uppercase()

        try {
            val level = PowerAuthLogLevel.valueOf(levelString)
            PowerAuthLogger.level = level

            result.success(null)
        } catch (e: IllegalArgumentException) {
            result.error(Errors.EC_INVALID_LOG_LEVEL, "Invalid log level: $levelString", null)
        }
    }

    private fun setNativeLoggingEnabled(call: MethodCall, result: Result) {
        val enabled = call.getRequiredArgument<Boolean>(ENABLED)

        PowerAuthLogger.enabled = enabled
        result.success(null)
    }
} 