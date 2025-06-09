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
import com.wultra.android.powerauth.flutter.WrapperException
import com.wultra.android.powerauth.flutter.internal.core.BasePowerAuthService
import com.wultra.android.powerauth.flutter.internal.core.PowerAuthFlutterService.MethodHandler
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import io.getlime.security.powerauth.core.ActivationCode
import io.getlime.security.powerauth.core.ActivationCodeUtil

internal class PowerAuthUtilsService : BasePowerAuthService(null) {

    override val name = "util"

    companion object ArgKeys {
        const val ACTIVATION_CODE = "activationCode"
        const val ACTIVATION_SIGNATURE = "activationSignature"
        const val CHARACTER = "character"
    }

    private object HandlerNames {
        const val UTIL_PARSE_ACTIVATION_CODE = "parseActivationCode"
        const val UTIL_VALIDATE_ACTIVATION_CODE = "validateActivationCode"
        const val UTIL_VALIDATE_TYPED_CHARACTER = "validateTypedCharacter"
        const val UTIL_CORRECT_TYPED_CHARACTER = "correctTypedCharacter"
    }

    override val handlers by lazy {
        mapOf(
            HandlerNames.UTIL_PARSE_ACTIVATION_CODE to MethodHandler { call, result ->
                parseActivationCode(
                    call,
                    result
                )
            },
            HandlerNames.UTIL_VALIDATE_ACTIVATION_CODE to MethodHandler { call, result ->
                validateActivationCode(
                    call,
                    result
                )
            },
            HandlerNames.UTIL_VALIDATE_TYPED_CHARACTER to MethodHandler { call, result ->
                validateTypedCharacter(
                    call,
                    result
                )
            },
            HandlerNames.UTIL_CORRECT_TYPED_CHARACTER to MethodHandler { call, result ->
                correctTypedCharacter(
                    call,
                    result
                )
            },
        )
    }

    private fun parseActivationCode(call: MethodCall, result: Result) {
        try {
            val activationCodeString: String = call.getRequiredArgument(ACTIVATION_CODE)
            val ac: ActivationCode? = ActivationCodeUtil.parseFromActivationCode(activationCodeString)

            if (ac != null) {
                val response = mutableMapOf<String, String?>(
                    ACTIVATION_CODE to ac.activationCode
                )

                ac.activationSignature?.let { response[ACTIVATION_SIGNATURE] = it }

                result.success(response)
            } else {
                result.error(Errors.EC_INVALID_ACTIVATION_CODE, "Invalid activation code provided.", null)
            }
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun validateActivationCode(call: MethodCall, result: Result) {
        try {
            val activationCodeString: String = call.getRequiredArgument(ACTIVATION_CODE)

            result.success(ActivationCodeUtil.validateActivationCode(activationCodeString))
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun validateTypedCharacter(call: MethodCall, result: Result) {
        try {
            val characterInt: Int = call.getRequiredArgument(CHARACTER)
            result.success(ActivationCodeUtil.validateTypedCharacter(characterInt))
        } catch (e: NumberFormatException) {
            Errors.error(result, WrapperException(Errors.EC_WRONG_PARAMETER, "Invalid character format, expected Int", e))
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun correctTypedCharacter(call: MethodCall, result: Result) {
        try {
            val characterInt: Int = call.getRequiredArgument(CHARACTER)
            val corrected: Int = ActivationCodeUtil.validateAndCorrectTypedCharacter(characterInt)

            if (corrected == 0) {
                result.error(Errors.EC_INVALID_CHARACTER, "Invalid character that cannot be corrected.", null)
            } else {
                result.success(corrected)
            }
        } catch (e: NumberFormatException) {
            Errors.error(result, WrapperException(Errors.EC_WRONG_PARAMETER, "Invalid character format, expected Int", e))
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }
}
