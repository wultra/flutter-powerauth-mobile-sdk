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
package com.wultra.android.powerauth.flutter

import io.flutter.plugin.common.MethodChannel.Result
import io.getlime.security.powerauth.exception.PowerAuthErrorCodes
import io.getlime.security.powerauth.exception.PowerAuthErrorException
import io.getlime.security.powerauth.networking.exceptions.ErrorResponseApiException
import io.getlime.security.powerauth.networking.exceptions.FailedApiException
import java.io.IOException

@Suppress("MemberVisibilityCanBePrivate")
object Errors {
    const val EC_FLUTTER_ERROR: String = "FLUTTER_ERROR"
    const val EC_AUTHENTICATION_ERROR: String = "AUTHENTICATION_ERROR"
    const val EC_RESPONSE_ERROR: String = "RESPONSE_ERROR"
    const val EC_INSTANCE_NOT_CONFIGURED: String = "INSTANCE_NOT_CONFIGURED"
    const val EC_INVALID_CHARACTER: String = "INVALID_CHARACTER"
    const val EC_CANNOT_GENERATE_TOKEN: String = "CANNOT_GENERATE_TOKEN"
    const val EC_LOCAL_TOKEN_NOT_AVAILABLE: String = "LOCAL_TOKEN_NOT_AVAILABLE"
    const val EC_BIOMETRY_FAILED: String = "BIOMETRY_FAILED"
    const val EC_INVALID_ACTIVATION_OBJECT: String = "INVALID_ACTIVATION_OBJECT"
    const val EC_INVALID_NATIVE_OBJECT: String = "INVALID_NATIVE_OBJECT"

    const val EC_SUCCEED: String = "SUCCEED"
    const val EC_NETWORK_ERROR: String = "NETWORK_ERROR"
    const val EC_SIGNATURE_ERROR: String = "SIGNATURE_ERROR"
    const val EC_INVALID_ACTIVATION_STATE: String = "INVALID_ACTIVATION_STATE"
    const val EC_INVALID_ACTIVATION_DATA: String = "INVALID_ACTIVATION_DATA"
    const val EC_MISSING_ACTIVATION: String = "MISSING_ACTIVATION"
    const val EC_PENDING_ACTIVATION: String = "PENDING_ACTIVATION"
    const val EC_BIOMETRY_CANCEL: String = "BIOMETRY_CANCEL"
    const val EC_OPERATION_CANCELED: String = "OPERATION_CANCELED"
    const val EC_INVALID_ACTIVATION_CODE: String = "INVALID_ACTIVATION_CODE"
    const val EC_INVALID_TOKEN: String = "INVALID_TOKEN"
    const val EC_INVALID_ENCRYPTOR: String = "INVALID_ENCRYPTOR"
    const val EC_ENCRYPTION_ERROR: String = "ENCRYPTION_ERROR"
    const val EC_WRONG_PARAMETER: String = "WRONG_PARAMETER"
    const val EC_PROTOCOL_UPGRADE: String = "PROTOCOL_UPGRADE"
    const val EC_PENDING_PROTOCOL_UPGRADE: String = "PENDING_PROTOCOL_UPGRADE"
    const val EC_BIOMETRY_NOT_SUPPORTED: String = "BIOMETRY_NOT_SUPPORTED"
    const val EC_BIOMETRY_NOT_AVAILABLE: String = "BIOMETRY_NOT_AVAILABLE"
    const val EC_BIOMETRY_NOT_RECOGNIZED: String = "BIOMETRY_NOT_RECOGNIZED"
    const val EC_BIOMETRY_NOT_CONFIGURED: String = "BIOMETRY_NOT_CONFIGURED"
    const val EC_BIOMETRY_NOT_ENROLLED: String = "BIOMETRY_NOT_ENROLLED"
    const val EC_TIME_SYNCHRONIZATION: String = "TIME_SYNCHRONIZATION"
    const val EC_BIOMETRY_LOCKOUT: String = "BIOMETRY_LOCKOUT"
    const val EC_UNKNOWN_ERROR: String = "UNKNOWN_ERROR"

    fun getErrorCodeFromError(@PowerAuthErrorCodes error: Int): String {
        return when (error) {
            PowerAuthErrorCodes.SUCCEED -> EC_SUCCEED
            PowerAuthErrorCodes.NETWORK_ERROR -> EC_NETWORK_ERROR
            PowerAuthErrorCodes.SIGNATURE_ERROR -> EC_SIGNATURE_ERROR
            PowerAuthErrorCodes.INVALID_ACTIVATION_STATE -> EC_INVALID_ACTIVATION_STATE
            PowerAuthErrorCodes.INVALID_ACTIVATION_DATA -> EC_INVALID_ACTIVATION_DATA
            PowerAuthErrorCodes.MISSING_ACTIVATION -> EC_MISSING_ACTIVATION
            PowerAuthErrorCodes.PENDING_ACTIVATION -> EC_PENDING_ACTIVATION
            PowerAuthErrorCodes.BIOMETRY_CANCEL -> EC_BIOMETRY_CANCEL
            PowerAuthErrorCodes.OPERATION_CANCELED -> EC_OPERATION_CANCELED
            PowerAuthErrorCodes.INVALID_ACTIVATION_CODE -> EC_INVALID_ACTIVATION_CODE
            PowerAuthErrorCodes.INVALID_TOKEN -> EC_INVALID_TOKEN
            PowerAuthErrorCodes.ENCRYPTION_ERROR -> EC_ENCRYPTION_ERROR
            PowerAuthErrorCodes.WRONG_PARAMETER -> EC_WRONG_PARAMETER
            PowerAuthErrorCodes.PROTOCOL_UPGRADE -> EC_PROTOCOL_UPGRADE
            PowerAuthErrorCodes.PENDING_PROTOCOL_UPGRADE -> EC_PENDING_PROTOCOL_UPGRADE
            PowerAuthErrorCodes.BIOMETRY_NOT_SUPPORTED -> EC_BIOMETRY_NOT_SUPPORTED
            PowerAuthErrorCodes.BIOMETRY_NOT_AVAILABLE -> EC_BIOMETRY_NOT_AVAILABLE
            PowerAuthErrorCodes.BIOMETRY_NOT_RECOGNIZED -> EC_BIOMETRY_NOT_RECOGNIZED
            PowerAuthErrorCodes.BIOMETRY_LOCKOUT -> EC_BIOMETRY_LOCKOUT
            PowerAuthErrorCodes.TIME_SYNCHRONIZATION -> EC_TIME_SYNCHRONIZATION
            else -> EC_UNKNOWN_ERROR
        }
    }

    // TODO: this is mostly copy-pase from RN, we might need some more/better translation to Flutter errors
    fun error(result: Result, t: Throwable) {
        var code = EC_FLUTTER_ERROR
        var message = t.message ?: "An unknown error occurred."
        var details: Any? = null

        when (t) {
            is WrapperException -> {
                code = t.errorCode
            }
            is PowerAuthErrorException -> {
                code = getErrorCodeFromError(t.powerAuthErrorCode)
                // Add PowerAuth error details if available
                val errorDetails = mutableMapOf<String, Any?>("originalCode" to t.powerAuthErrorCode)

                t.message?.let { errorDetails["originalMessage"] = it }
                details = errorDetails
            }
            is FailedApiException -> {
                val httpStatusCode: Int = t.responseCode
                if (httpStatusCode == 401) {
                    code = EC_AUTHENTICATION_ERROR
                    message = "Unauthorized"
                } else {
                    code = EC_RESPONSE_ERROR
                }

                val errorDetails = mutableMapOf<String, Any?>(
                    "httpStatusCode" to httpStatusCode,
                    "responseBody" to t.responseBody
                )

                if (t is ErrorResponseApiException) {
                    errorDetails["serverResponseCode"] = t.errorResponse.code
                    errorDetails["serverResponseMessage"] = t.errorResponse.message
                }

                details = errorDetails
            }
            is IOException -> {
                code = EC_NETWORK_ERROR
            }
            else -> {
                details = mapOf("nativeExceptionType" to t.javaClass.simpleName)
            }
        }

        result.error(code, message, details)
    }
} 