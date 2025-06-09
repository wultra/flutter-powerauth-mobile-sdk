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
import com.wultra.android.powerauth.flutter.PowerAuthObjectRegister
import com.wultra.android.powerauth.flutter.internal.core.BasePowerAuthService
import com.wultra.android.powerauth.flutter.internal.core.PowerAuthFlutterService.MethodHandler
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result

internal class PowerAuthRegisterService(private val objectRegister: PowerAuthObjectRegister) : BasePowerAuthService(objectRegister) {

    override val name: String = "register"

    private companion object ArgKeys {
        const val INSTANCE_ID = "instanceId"
        const val OBJECT_ID = "objectId"
        const val COMMAND = "command"
        const val DATA = "data"
    }

    private object HandlerNames {
        const val DEBUG_DUMP = "debugDump"
        const val DEBUG_COMMAND = "debugCommand"
        const val IS_VALID_NATIVE_OBJECT = "isValidNativeObject"
    }

    override val handlers by lazy {
        mapOf(
            HandlerNames.DEBUG_DUMP to MethodHandler { call, result -> debugDump(call, result) },
            HandlerNames.DEBUG_COMMAND to MethodHandler { call, result -> debugCommand(call, result) },
            HandlerNames.IS_VALID_NATIVE_OBJECT to MethodHandler { call, result -> isValidNativeObject(call, result) }
        )
    }

    private fun debugDump(call: MethodCall, result: Result) {
        try {
            val instanceId: String? = call.argument(INSTANCE_ID)
            result.success(objectRegister.debugDumpObjectsWithTag(instanceId))
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun debugCommand(call: MethodCall, result: Result) {
        try {
            val command: String = call.getRequiredArgument(COMMAND)
            val data: Map<String, Any> = call.getRequiredArgument(DATA)
            val res = objectRegister.debugCommand(command, data)

            result.success(res)
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun isValidNativeObject(call: MethodCall, result: Result) {
        try {
            val objectId: String = call.getRequiredArgument(OBJECT_ID)

            result.success(objectRegister.findObject(objectId, Any::class.java) != null)
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }
} 