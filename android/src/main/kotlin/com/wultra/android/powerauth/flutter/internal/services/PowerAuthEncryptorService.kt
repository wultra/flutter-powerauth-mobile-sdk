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

import android.content.Context
import com.wultra.android.powerauth.flutter.Constants
import com.wultra.android.powerauth.flutter.Errors
import com.wultra.android.powerauth.flutter.ManagedAny
import com.wultra.android.powerauth.flutter.PowerAuthObjectRegister
import com.wultra.android.powerauth.flutter.ReleasePolicy
import com.wultra.android.powerauth.flutter.WrapperException
import com.wultra.android.powerauth.flutter.internal.core.BasePowerAuthService
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import io.getlime.security.powerauth.core.CoreEncryptedResponse
import io.getlime.security.powerauth.core.CoreEncryptor
import io.getlime.security.powerauth.networking.response.IGetEncryptorListener
import io.getlime.security.powerauth.sdk.PowerAuthSDK

internal class PowerAuthEncryptorService(
    private val objectRegister: PowerAuthObjectRegister,
    @Suppress("UNUSED_PARAMETER") context: Context
) : BasePowerAuthService(objectRegister) {

    override val name = "encryptor"

    private companion object ArgKeys {
        const val SCOPE = "scope"
        const val INSTANCE_ID = "powerAuthInstanceId"
        const val OBJECT_ID = "objectId"
        const val REQUEST_BODY = "requestBody"
        const val RESPONSE_BODY = "responseBody"
    }

    private object HandlerNames {
        const val INITIALIZE = "initialize"
        const val CAN_ENCRYPT_REQUEST = "canEncryptRequest"
        const val ENCRYPT_REQUEST = "encryptRequest"
        const val CAN_DECRYPT_RESPONSE = "canDecryptResponse"
        const val DECRYPT_RESPONSE = "decryptResponse"
    }

    override val handlers by lazy {
        mapOf(
            HandlerNames.INITIALIZE to this::initialize,
            HandlerNames.CAN_ENCRYPT_REQUEST to this::canEncryptRequest,
            HandlerNames.ENCRYPT_REQUEST to this::encryptRequest,
            HandlerNames.CAN_DECRYPT_RESPONSE to this::canDecryptResponse,
            HandlerNames.DECRYPT_RESPONSE to this::decryptResponse
        )
    }

    private fun initialize(call: MethodCall, result: Result) {
        try {
            val scope: String = call.getRequiredArgument(SCOPE)
            val instanceId: String = call.getRequiredArgument(INSTANCE_ID)
            val isActivationScope = when (scope) {
                "application" -> false
                "activation" -> true
                else -> throw WrapperException(
                    Errors.EC_WRONG_PARAMETER,
                    "Unknown scope value: $scope"
                )
            }

            val sdk = objectRegister.findObject(instanceId, PowerAuthSDK::class.java)
                ?: throw WrapperException(
                    Errors.EC_INSTANCE_NOT_CONFIGURED,
                    "PowerAuth instance '$instanceId' not configured."
                )

            val listener = object : IGetEncryptorListener {
                override fun onGetEncryptorSuccess(encryptor: CoreEncryptor) {
                    try {
                        //check if sdk has not been deconfigured in the meantime
                        val objectId = objectRegister.registerObjectIfOwnerMatches(
                            instanceId,
                            sdk,
                            ManagedAny.wrap(encryptor) { it.destroy() },
                            listOf(ReleasePolicy.keepAlive(Constants.ENCRYPTOR_KEEP_ALIVE_TIME))
                        ) ?: throw WrapperException(
                            Errors.EC_INSTANCE_NOT_CONFIGURED,
                            "PowerAuth instance '$instanceId' not configured."
                        )
                        result.success(objectId)
                    } catch (t: Throwable) {
                        encryptor.destroy()
                        Errors.error(result, t)
                    }
                }

                override fun onGetEncryptorFailed(t: Throwable) {
                    Errors.error(result, t)
                }
            }

            if (isActivationScope) {
                sdk.getEncryptorForActivationScope(listener)
            } else {
                sdk.getEncryptorForApplicationScope(listener)
            }
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun canEncryptRequest(call: MethodCall, result: Result) {
        withEncryptor(call, result) { encryptor ->
            encryptor.canEncryptRequest()
        }
    }

    private fun encryptRequest(call: MethodCall, result: Result) {
        withEncryptor(call, result) { encryptor ->
            val requestBody: ByteArray? = call.argument(REQUEST_BODY)
            val encryptedRequest = encryptor.encryptRequest(requestBody)

            mapOf(
                "requestBody" to encryptedRequest.requestBody,
                "requestHeaders" to encryptedRequest.requestHeaders.map { header ->
                    mapOf("name" to header.key, "value" to header.value)
                }
            )
        }
    }

    private fun canDecryptResponse(call: MethodCall, result: Result) {
        withEncryptor(call, result) { encryptor ->
            encryptor.canDecryptResponse()
        }
    }

    private fun decryptResponse(call: MethodCall, result: Result) {
        val responseBody: ByteArray = try {
            call.getRequiredArgument(RESPONSE_BODY)
        } catch (t: Throwable) {
            Errors.error(result, t)
            return
        }

        withEncryptor(call, result, destroyAfter = true) { encryptor ->
            encryptor.decryptResponse(CoreEncryptedResponse(responseBody))
        }
    }

    private fun <T : Any> withEncryptor(
        call: MethodCall,
        result: Result,
        destroyAfter: Boolean = false,
        block: (CoreEncryptor) -> T
    ) {
        val objectId: String = call.getRequiredArgument(OBJECT_ID)
        try {
            val value = objectRegister.useObjectAndTransform(
                objectId,
                CoreEncryptor::class.java
            ) { encryptor ->
                block(encryptor)

            } ?: throw WrapperException(
                Errors.EC_INVALID_NATIVE_OBJECT,
                "Encryptor object '$objectId' is no longer valid."
            )
            result.success(value)
        } catch (t: Throwable) {
            Errors.error(result, t)
        } finally {
            if (destroyAfter) {
                objectRegister.removeObject(objectId, CoreEncryptor::class.java)
            }
        }
    }

}
