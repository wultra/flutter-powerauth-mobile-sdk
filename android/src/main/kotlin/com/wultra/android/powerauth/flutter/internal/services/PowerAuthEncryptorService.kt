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
import com.wultra.android.powerauth.flutter.PowerAuthObjectRegister
import com.wultra.android.powerauth.flutter.ReleasePolicy
import com.wultra.android.powerauth.flutter.WrapperException
import com.wultra.android.powerauth.flutter.internal.core.BasePowerAuthService
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import io.getlime.security.powerauth.core.EciesCryptogram
import io.getlime.security.powerauth.core.EciesEncryptor
import io.getlime.security.powerauth.ecies.EciesMetadata
import io.getlime.security.powerauth.exception.PowerAuthErrorCodes
import io.getlime.security.powerauth.exception.PowerAuthErrorException
import io.getlime.security.powerauth.networking.response.IGetEciesEncryptorListener
import io.getlime.security.powerauth.sdk.PowerAuthSDK
import com.wultra.android.powerauth.flutter.DataFormat
import com.wultra.android.powerauth.flutter.IManagedObject
import com.wultra.android.powerauth.flutter.internal.core.PowerAuthFlutterService.MethodHandler

private data class PowerAuthFlutterEncryptor(
    val activationScoped: Boolean,
    val coreEncryptor: EciesEncryptor,
    val powerAuthInstanceId: String
): IManagedObject<Any> {

    override fun cleanup() {
        coreEncryptor.destroy()
    }

    override fun managedInstance(): IManagedObject<Any> {
        return this
    }
}

class PowerAuthEncryptorService(
    private val objectRegister: PowerAuthObjectRegister,
    private val context: Context
) : BasePowerAuthService(objectRegister) {

    override val name = "encryptor"

    private companion object ArgKeys {
        const val SCOPE = "scope"
        const val INSTANCE_ID = "powerAuthInstanceId"
        const val AUTO_RELEASE_TIME_MILLIS = "autoReleaseTimeMillis"
        const val OBJECT_ID = "objectId"
        const val BODY = "body"
        const val BODY_FORMAT = "bodyFormat"
        const val CRYPTOGRAM = "cryptogram"
        const val OUTPUT_DATA_FORMAT = "outputDataFormat"
    }

    private object HandlerNames {
        const val INITIALIZE = "initialize"
        const val RELEASE = "release"
        const val CAN_ENCRYPT_REQUEST = "canEncryptRequest"
        const val ENCRYPT_REQUEST = "encryptRequest"
        const val CAN_DECRYPT_RESPONSE = "canDecryptResponse"
        const val DECRYPT_RESPONSE = "decryptResponse"
    }

    override val handlers by lazy {
        mapOf(
            HandlerNames.INITIALIZE to MethodHandler { call, result ->
                initialize(
                    call,
                    result
                )
            },
            HandlerNames.RELEASE to MethodHandler { call, result -> release(call, result) },
            HandlerNames.CAN_ENCRYPT_REQUEST to MethodHandler { call, result -> canEncryptRequest(call, result) },
            HandlerNames.ENCRYPT_REQUEST to MethodHandler { call, result -> encryptRequest(call, result) },
            HandlerNames.CAN_DECRYPT_RESPONSE to MethodHandler { call, result -> canDecryptResponse(call, result) },
            HandlerNames.DECRYPT_RESPONSE to MethodHandler { call, result -> decryptResponse(call, result) }
        )
    }

    private fun initialize(call: MethodCall, result: Result) {
        try {
            val scope: String = call.getRequiredArgument(SCOPE)
            val powerAuthInstanceId: String = call.getRequiredArgument(INSTANCE_ID)
            val autoReleaseTimeMillis: Int? = call.argument(AUTO_RELEASE_TIME_MILLIS)

            val isActivationScope = when (scope) {
                "application" -> false
                "activation" -> true
                else -> throw WrapperException(Errors.EC_WRONG_PARAMETER, "Unknown scope value: $scope")
            }

            val sdk = objectRegister.findObject(powerAuthInstanceId, PowerAuthSDK::class.java)
                ?: throw WrapperException(Errors.EC_INSTANCE_NOT_CONFIGURED, "PowerAuth instance '$powerAuthInstanceId' not configured.")

            val listener = object : IGetEciesEncryptorListener {
                override fun onGetEciesEncryptorSuccess(encryptor: EciesEncryptor) {
                    val flutterEncryptor = PowerAuthFlutterEncryptor(isActivationScope, encryptor, powerAuthInstanceId)
                    val releaseTime = autoReleaseTimeMillis ?: Constants.ENCRYPTOR_KEY_KEEP_ALIVE_TIME
                    val policies = listOf(ReleasePolicy.keepAlive(releaseTime))
                    val objectId = objectRegister.registerObject(flutterEncryptor, powerAuthInstanceId, policies)
                    result.success(objectId)
                }

                override fun onGetEciesEncryptorFailed(t: Throwable) {
                    if (isActivationScope && !sdk.hasValidActivation()) {
                        Errors.error(result, PowerAuthErrorException(PowerAuthErrorCodes.MISSING_ACTIVATION))
                    } else {
                        Errors.error(result, t)
                    }
                }
            }

            if (isActivationScope) {
                sdk.getEciesEncryptorForActivationScope(context, listener)
            } else {
                sdk.getEciesEncryptorForApplicationScope(listener)
            }
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun release(call: MethodCall, result: Result) {
        try {
            val objectId: String = call.getRequiredArgument(OBJECT_ID)
            objectRegister.removeObject(objectId)
            result.success(null)
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun canEncryptRequest(call: MethodCall, result: Result) {
        withEncryptor(call, result, touch = true) { encryptor, sdk ->
            val canEncrypt = canEncrypt(encryptor, sdk)
            result.success(canEncrypt)
        }
    }

    private fun encryptRequest(call: MethodCall, result: Result) {
        withEncryptor(call, result, touch = false) { encryptor, sdk ->
            val objectId: String = call.getRequiredArgument(OBJECT_ID)
            val body: String = call.getRequiredArgument(BODY)
            val bodyFormat: String = call.getRequiredArgument(BODY_FORMAT)
            val data = DataFormat.fromString(bodyFormat).decodeBytes(body)

            if (!canEncrypt(encryptor, sdk)) {
                objectRegister.removeObject(objectId)
                throw WrapperException(Errors.EC_INVALID_ENCRYPTOR, "Encryptor is not constructed for request encryption.")
            }

            val encryptionResult = encryptor.coreEncryptor.encryptRequestSynchronized(data)
                ?: throw WrapperException(Errors.EC_ENCRYPTION_ERROR, "Failed to encrypt request")

            val decryptorEncryptor = encryptionResult.first
            val cryptogram = encryptionResult.second

            val metadata: EciesMetadata = decryptorEncryptor.metadata
                ?: throw WrapperException(Errors.EC_INVALID_ENCRYPTOR, "Incompatible native SDK")

            val decryptor = PowerAuthFlutterEncryptor(encryptor.activationScoped, decryptorEncryptor, encryptor.powerAuthInstanceId)

            val policies = listOf(
                ReleasePolicy.afterUse(1),
                ReleasePolicy.keepAlive(Constants.DECRYPTOR_KEY_KEEP_ALIVE_TIME)
            )

            val decryptorId = objectRegister.registerObject(decryptor, encryptor.powerAuthInstanceId, policies)

            val cryptogramMap = mapOf(
                "temporaryKeyId" to cryptogram.temporaryKeyId,
                "ephemeralPublicKey" to cryptogram.keyBase64,
                "encryptedData" to cryptogram.bodyBase64,
                "mac" to cryptogram.macBase64,
                "nonce" to cryptogram.nonceBase64,
                "timestamp" to cryptogram.timestamp
            )

            val headerMap = mapOf(
                "name" to metadata.httpHeaderKey,
                "value" to metadata.httpHeaderValue
            )

            result.success(mapOf(
                "cryptogram" to cryptogramMap,
                "header" to headerMap,
                "decryptorId" to decryptorId
            ))
        }
    }

    private fun canDecryptResponse(call: MethodCall, result: Result) {
        withEncryptor(call, result, touch = true) { encryptor, sdk ->
            val canDecrypt = canDecrypt(encryptor, sdk)
            result.success(canDecrypt)
        }
    }

    private fun decryptResponse(call: MethodCall, result: Result) {
        withEncryptor(call, result, touch = false) { encryptor, sdk ->
            val objectId: String = call.getRequiredArgument(OBJECT_ID)
            val cryptogramMap: Map<String, Any> = call.getRequiredArgument(CRYPTOGRAM)
            val outputDataFormat: String = call.getRequiredArgument(OUTPUT_DATA_FORMAT)

            if (!canDecrypt(encryptor, sdk)) {
                objectRegister.removeObject(objectId)
                throw WrapperException(Errors.EC_INVALID_ENCRYPTOR, "Encryptor is not constructed for response decryption.")
            }

            val cryptogram = EciesCryptogram(
                cryptogramMap["temporaryKeyId"] as String?,
                cryptogramMap["encryptedData"] as String?,
                cryptogramMap["mac"] as String?,
                cryptogramMap["ephemeralPublicKey"] as String?,
                cryptogramMap["nonce"] as String?,
                cryptogramMap["timestamp"] as Long,
            )

            val decryptedData = encryptor.coreEncryptor.decryptResponse(cryptogram)
                ?: throw WrapperException(Errors.EC_ENCRYPTION_ERROR, "Failed to decrypt response.")

            result.success(DataFormat.fromString(outputDataFormat).encodeBytes(decryptedData))
        }
    }

    private fun withEncryptor(call: MethodCall, result: Result, touch: Boolean, block: (PowerAuthFlutterEncryptor, PowerAuthSDK) -> Unit) {
        try {
            val objectId: String = call.getRequiredArgument(OBJECT_ID)
            val encryptor = if (touch) {
                objectRegister.touchObject(objectId, PowerAuthFlutterEncryptor::class.java)
            } else {
                objectRegister.useObject(objectId, PowerAuthFlutterEncryptor::class.java)
            } ?: throw WrapperException(Errors.EC_INVALID_NATIVE_OBJECT, "Encryptor object '$objectId' is no longer valid.")

            val sdk = objectRegister.findObject(encryptor.powerAuthInstanceId, PowerAuthSDK::class.java)
                ?: throw WrapperException(Errors.EC_INSTANCE_NOT_CONFIGURED, "PowerAuth instance '${encryptor.powerAuthInstanceId}' not configured.")

            block(encryptor, sdk)
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun canEncrypt(encryptor: PowerAuthFlutterEncryptor, sdk: PowerAuthSDK): Boolean {
        if (encryptor.activationScoped && !sdk.hasValidActivation()) {
            return false
        }

        return encryptor.coreEncryptor.canEncryptRequest()
    }

    private fun canDecrypt(encryptor: PowerAuthFlutterEncryptor, sdk: PowerAuthSDK): Boolean {
        if (encryptor.activationScoped && !sdk.hasValidActivation()) {
            return false
        }

        return encryptor.coreEncryptor.canDecryptResponse()
    }
}
