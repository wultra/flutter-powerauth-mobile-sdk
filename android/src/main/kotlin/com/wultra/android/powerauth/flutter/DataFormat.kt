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

import android.util.Base64
import java.nio.charset.StandardCharsets

/**
 * Defines data format used for encode bytes into the string.
 */
enum class DataFormat {
    /**
     * Application provides data in form of UTF-8 encoded string.
     */
    UTF8,

    /**
     * Application provides data in form of Base64 encoded string.
     */
    BASE64;

    /**
     * Decode bytes from application provided string with using this data format.
     * @param value String with encoded bytes.
     * @return Decoded bytes.
     * @throws WrapperException In case of failure.
     */
    @Throws(WrapperException::class)
    fun decodeBytes(value: String?): ByteArray {
        return if (value != null) {
            when (this) {
                UTF8 -> value.toByteArray(StandardCharsets.UTF_8)
                BASE64 -> try {
                    Base64.decode(value, Base64.NO_WRAP)
                } catch (e: IllegalArgumentException) {
                    throw WrapperException(
                        Errors.EC_WRONG_PARAMETER,
                        "Failed to decode Base64 encoded data.",
                        e
                    )
                }
            }
        } else {
            ByteArray(0)
        }
    }

    /**
     * Encode bytes into this data format.
     * @param value Bytes to encode.
     * @return Encoded bytes.
     * @throws WrapperException In case of failure.
     */
    @Throws(WrapperException::class)
    fun encodeBytes(value: ByteArray?): String {
        if (value == null || value.isEmpty()) {
            return ""
        }
        return when (this) {
            UTF8 -> try {
                String(value, StandardCharsets.UTF_8)
            } catch (t: Throwable) {
                throw WrapperException(
                    Errors.EC_WRONG_PARAMETER,
                    "Failed to create string from UTF-8 encoded data",
                    t
                )
            }

            BASE64 -> Base64.encodeToString(value, Base64.NO_WRAP)
        }
    }

    companion object {
        /**
         * Convert format string into this enumeration.
         * @param format Specified data format. If `null` then `UTF8` is returned.
         * @return Enumeration with data format.
         * @throws WrapperException In case of uknown format is specified.
         */
        @Throws(WrapperException::class)
        fun fromString(format: String?): DataFormat {
            return when (format?.uppercase()) {
                null -> UTF8
                "UTF8" -> UTF8
                "BASE64" -> BASE64
                else -> throw WrapperException(
                    Errors.EC_WRONG_PARAMETER,
                    "Invalid data format specified"
                )
            }
        }
    }
} 