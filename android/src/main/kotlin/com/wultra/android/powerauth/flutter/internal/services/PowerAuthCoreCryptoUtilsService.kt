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

import com.wultra.android.powerauth.flutter.DataFormat
import com.wultra.android.powerauth.flutter.Errors
import com.wultra.android.powerauth.flutter.WrapperException
import com.wultra.android.powerauth.flutter.internal.core.BasePowerAuthService
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import io.getlime.security.powerauth.core.CryptoUtils

/**
 * Service exposing basic cryptographic utilities backed by platform primitives.
 * Methods:
 *  - randomBytes: Generate random bytes of given length, returned as Base64 by default.
 *  - hashSha256: Compute SHA-256 hash of input data.
 */
internal class PowerAuthCoreCryptoUtilsService : BasePowerAuthService(null) {

    override val name = "cryptoUtils"

    private companion object ArgKeys {
        const val LENGTH = "length"
        const val DATA = "data"
        const val DATA_FORMAT = "dataFormat"
        const val OUTPUT_DATA_FORMAT = "outputDataFormat"
    }

    private object HandlerNames {
        const val RANDOM_BYTES = "randomBytes"
        const val HASH_SHA256 = "hashSha256"
    }

    override val handlers by lazy {
        mapOf(
            HandlerNames.RANDOM_BYTES to this::randomBytes,
            HandlerNames.HASH_SHA256 to this::hashSha256
        )
    }

    private fun randomBytes(call: MethodCall, result: Result) {
        try {
            val length: Int = call.getRequiredArgument(LENGTH)
            if (length < 0) {
                throw WrapperException(Errors.EC_WRONG_PARAMETER, "Length must be non-negative")
            }

            val bytes = CryptoUtils.randomBytes(length)
            result.success(bytes)
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun hashSha256(call: MethodCall, result: Result) {
        try {
            val dataBytes: ByteArray = call.getRequiredArgument(DATA)
            val digest = CryptoUtils.hashSha256(dataBytes)
            result.success(digest)
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }
}