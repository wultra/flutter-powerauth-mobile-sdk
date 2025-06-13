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

import com.wultra.android.powerauth.flutter.PowerAuthObjectRegister
import com.wultra.android.powerauth.flutter.internal.core.BasePowerAuthService
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import io.getlime.security.powerauth.core.Password
import com.wultra.android.powerauth.flutter.Constants
import com.wultra.android.powerauth.flutter.Errors
import com.wultra.android.powerauth.flutter.ManagedAny
import com.wultra.android.powerauth.flutter.ReleasePolicy
import com.wultra.android.powerauth.flutter.WrapperException
import io.getlime.security.powerauth.sdk.PowerAuthSDK

internal class PowerAuthPasswordService(
    private val objectRegister: PowerAuthObjectRegister
) : BasePowerAuthService(objectRegister) {

    override val name = "password"

    companion object ArgKeys {
        const val CHARACTER = "character"
        const val OBJECT_ID = "objectId"
        const val OTHER_OBJECT_ID = "otherObjectId"
        const val DESTROY_ON_USE = "destroyOnUse"
        const val AUTORELEASE_TIME = "autoreleaseTime"
        const val OWNER_ID = "ownerId"
        const val POSITION = "position"
    }

    private object HandlerNames {
        const val PASSWORD_INITIALIZE = "initialize"
        const val PASSWORD_RELEASE = "release"
        const val PASSWORD_CLEAR = "clear"
        const val PASSWORD_LENGTH = "length"
        const val PASSWORD_IS_EQUAL = "isEqualTo"
        const val PASSWORD_ADD_CHARACTER = "addCharacter"
        const val PASSWORD_INSERT_CHARACTER = "insertCharacter"
        const val PASSWORD_REMOVE_CHARACTER_AT = "removeCharacterAt"
        const val PASSWORD_REMOVE_LAST_CHARACTER = "removeLastCharacter"
    }

    override val handlers by lazy {
        mapOf(
            HandlerNames.PASSWORD_INITIALIZE to this::initialize,
            HandlerNames.PASSWORD_RELEASE to this::release,
            HandlerNames.PASSWORD_CLEAR to this::clear,
            HandlerNames.PASSWORD_LENGTH to this::length,
            HandlerNames.PASSWORD_ADD_CHARACTER to this::addCharacter,
            HandlerNames.PASSWORD_INSERT_CHARACTER to this::insertCharacter,
            HandlerNames.PASSWORD_REMOVE_LAST_CHARACTER to this::removeLastCharacter,
            HandlerNames.PASSWORD_REMOVE_CHARACTER_AT to this::removeCharacterAt,
            HandlerNames.PASSWORD_IS_EQUAL to this::isEqual
        )
    }

    private fun <T> withPassword(
        call: MethodCall,
        result: Result,
        block: (password: Password) -> T
    ) {
        try {
            val objectId: String = call.getRequiredArgument(OBJECT_ID)
            val password = objectRegister.touchObject(objectId, Password::class.java)
                ?: throw WrapperException(
                    Errors.EC_INVALID_NATIVE_OBJECT,
                    "Password object '$objectId' is no longer valid or not found."
                )

            val blockResult = block(password)

            if (blockResult is Unit) {
                result.success(null)
            } else {
                result.success(blockResult)
            }
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun <T> withPasswordAndCharacter(
        call: MethodCall,
        result: Result,
        block: (password: Password, codePoint: Int) -> T
    ) {
        try {
            val objectId: String = call.getRequiredArgument(OBJECT_ID)
            val characterInt: Int = call.getRequiredArgument(CHARACTER)

            if (characterInt < 0 || characterInt > Constants.CODEPOINT_MAX) {
                throw WrapperException(
                    Errors.EC_WRONG_PARAMETER,
                    "Invalid CodePoint: $characterInt"
                )
            }

            val password = objectRegister.touchObject(objectId, Password::class.java)
                ?: throw WrapperException(
                    Errors.EC_INVALID_NATIVE_OBJECT,
                    "Password object '$objectId' is no longer valid or not found."
                )

            val blockResult = block(password, characterInt)

            if (blockResult is Unit) {
                result.success(null)
            } else {
                result.success(blockResult)
            }
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun initialize(call: MethodCall, result: Result) {
        try {
            val destroyOnUse: Boolean = call.argument<Boolean>(DESTROY_ON_USE) ?: false
            val ownerId: String? = call.argument<String>(OWNER_ID)
            val autoreleaseTimeMs: Int =
                call.argument<Int>(AUTORELEASE_TIME) ?: Constants.PASSWORD_KEY_KEEP_ALIVE_TIME

            if (ownerId != null && objectRegister.findObject(
                    ownerId,
                    PowerAuthSDK::class.java
                ) == null
            ) {
                throw WrapperException(
                    Errors.EC_INSTANCE_NOT_CONFIGURED,
                    "PowerAuth instance for ownerId '$ownerId' is not configured."
                )
            }

            var actualReleaseTime = Constants.PASSWORD_KEY_KEEP_ALIVE_TIME

            if (autoreleaseTimeMs > 0) {
                actualReleaseTime = autoreleaseTimeMs
            }

            val passwordInstance = ManagedAny.wrap(Password()) { obj: Password -> obj.destroy() }

            val releasePolicies = mutableListOf<ReleasePolicy>()
            if (destroyOnUse) {
                releasePolicies.add(ReleasePolicy.afterUse(1))
            }
            releasePolicies.add(ReleasePolicy.keepAlive(actualReleaseTime))

            val objectId = objectRegister.registerObject(passwordInstance, ownerId, releasePolicies)
            result.success(objectId)
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun clear(call: MethodCall, result: Result) {
        withPassword(call, result) { password ->
            return@withPassword password.clear()
        }
    }

    private fun length(call: MethodCall, result: Result) {
        withPassword(call, result) { password ->
            return@withPassword password.length()
        }
    }

    private fun isEqual(call: MethodCall, result: Result) {
        try {
            val id1: String = call.getRequiredArgument(OBJECT_ID)
            val id2: String = call.getRequiredArgument(OTHER_OBJECT_ID)

            val p1 = objectRegister.touchObject(id1, Password::class.java)
                ?: throw WrapperException(
                    Errors.EC_INVALID_NATIVE_OBJECT,
                    "Password object '$id1' is no longer valid or not found."
                )
            val p2 = objectRegister.touchObject(id2, Password::class.java)
                ?: throw WrapperException(
                    Errors.EC_INVALID_NATIVE_OBJECT,
                    "Password object '$id2' is no longer valid or not found."
                )

            result.success(p1.isEqualToPassword(p2))
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun addCharacter(call: MethodCall, result: Result) {
        withPasswordAndCharacter(call, result) { password, codePoint ->
            password.addCharacter(codePoint)

            return@withPasswordAndCharacter password.length()
        }
    }

    private fun insertCharacter(call: MethodCall, result: Result) {
        try {
            val position: Int = call.getRequiredArgument(POSITION)

            withPasswordAndCharacter(call, result) { password, codePoint ->
                if (position >= 0 && position <= password.length()) {
                    password.insertCharacter(codePoint, position)

                    return@withPasswordAndCharacter password.length()
                } else {
                    throw WrapperException(
                        Errors.EC_WRONG_PARAMETER,
                        "Position $position is out of range for password length ${password.length()}."
                    )
                }
            }
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun release(call: MethodCall, result: Result) {
        try {
            val objectId: String = call.getRequiredArgument(OBJECT_ID)
            objectRegister.removeObject(objectId, Password::class.java)

            result.success(null)
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun removeCharacterAt(call: MethodCall, result: Result) {
        try {
            val position: Int = call.getRequiredArgument(POSITION)

            withPassword(call, result) { password ->
                if (position >= 0 && position < password.length()) {
                    password.removeCharacter(position)

                    return@withPassword password.length()
                }
                throw WrapperException(
                    Errors.EC_WRONG_PARAMETER,
                    "Position $position is out of range for password length ${password.length()}."
                )
            }
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun removeLastCharacter(call: MethodCall, result: Result) {
        withPassword(call, result) { password ->
            if (password.length() > 0) {
                password.removeLastCharacter()
            }

            return@withPassword password.length()
        }
    }
}
