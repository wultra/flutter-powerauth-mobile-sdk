/*
 * Copyright 2026 Wultra s.r.o.
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

package com.wultra.android.powerauth.flutter.internal.utils

import com.wultra.android.powerauth.flutter.Errors
import com.wultra.android.powerauth.flutter.WrapperException
import io.getlime.security.powerauth.sdk.PowerAuthSignatureKeyId

object PowerAuthSignatureUtils {

    @PowerAuthSignatureKeyId
    fun signatureKeyIdFromString(value: String): Int {
        return when (value) {
            "master" -> PowerAuthSignatureKeyId.MASTER
            "masterEc" -> PowerAuthSignatureKeyId.MASTER_EC
            "masterMlDsa" -> PowerAuthSignatureKeyId.MASTER_ML_DSA
            "server" -> PowerAuthSignatureKeyId.SERVER
            "serverEc" -> PowerAuthSignatureKeyId.SERVER_EC
            "serverMlDsa" -> PowerAuthSignatureKeyId.SERVER_ML_DSA
            "device" -> PowerAuthSignatureKeyId.DEVICE
            "deviceEc" -> PowerAuthSignatureKeyId.DEVICE_EC
            "deviceMlDsa" -> PowerAuthSignatureKeyId.DEVICE_ML_DSA
            "macPersonalized" -> PowerAuthSignatureKeyId.MAC_PERSONALIZED
            else -> throw WrapperException(
                Errors.EC_WRONG_PARAMETER,
                "Unknown signature key identifier: $value"
            )
        }
    }
}