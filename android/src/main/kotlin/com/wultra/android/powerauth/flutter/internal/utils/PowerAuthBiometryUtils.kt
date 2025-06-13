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

package com.wultra.android.powerauth.flutter.internal.utils

import android.app.Activity
import android.content.Context
import android.os.Build
import android.util.Pair
import androidx.fragment.app.FragmentActivity
import com.wultra.android.powerauth.flutter.Constants
import com.wultra.android.powerauth.flutter.Errors
import com.wultra.android.powerauth.flutter.WrapperException
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthService.ArgKeys.PROMPT_MESSAGE
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthService.ArgKeys.PROMPT_TITLE
import io.flutter.plugin.common.MethodChannel.Result
import io.getlime.security.powerauth.biometry.BiometricAuthentication
import io.getlime.security.powerauth.biometry.BiometricStatus
import io.getlime.security.powerauth.biometry.BiometryType
import io.getlime.security.powerauth.keychain.KeychainProtection
import io.getlime.security.powerauth.sdk.PowerAuthSDK

object PowerAuthBiometryUtils {

    fun getBiometryInfo(context: Context, result: Result) {
        try {
            val isAvailable = BiometricAuthentication.isBiometricAuthenticationAvailable(context)

            val biometryType = when (BiometricAuthentication.getBiometryType(context)) {
                BiometryType.NONE -> "none"
                BiometryType.FINGERPRINT -> "fingerprint"
                BiometryType.FACE -> "face"
                BiometryType.IRIS -> "iris"
                BiometryType.GENERIC -> "generic"
                else -> "generic"
            }

            val canAuthenticate = when (BiometricAuthentication.canAuthenticate(context)) {
                BiometricStatus.OK -> "ok"
                BiometricStatus.NOT_ENROLLED -> "notEnrolled"
                BiometricStatus.NOT_AVAILABLE -> "notAvailable"
                BiometricStatus.NOT_SUPPORTED -> "notSupported"
                else -> "notSupported"
            }

            val map = mapOf(
                "isAvailable" to isAvailable,
                "biometryType" to biometryType,
                "canAuthenticate" to canAuthenticate
            )

            result.success(map)
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    fun extractPromptStrings(promptMap: Map<String, Any>?): Pair<String, String> {
        val title = promptMap?.get(PROMPT_TITLE) as? String ?: Constants.MISSING_REQUIRED_STRING
        val description =
            promptMap?.get(PROMPT_MESSAGE) as? String ?: Constants.MISSING_REQUIRED_STRING
        return Pair(title, description)
    }

    @Throws(WrapperException::class)
    fun validateBiometryBeforeUse(context: Context, sdk: PowerAuthSDK) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            when (val status = BiometricAuthentication.canAuthenticate(context)) {
                BiometricStatus.OK -> {
                    if (sdk.hasValidActivation() && !sdk.hasBiometryFactor(context)) {
                        throw WrapperException(
                            Errors.EC_BIOMETRY_NOT_CONFIGURED,
                            "Biometry factor is not configured for this activation."
                        )
                    }
                }

                BiometricStatus.NOT_AVAILABLE -> throw WrapperException(
                    Errors.EC_BIOMETRY_NOT_AVAILABLE,
                    "Biometry is not available on this device currently."
                )

                BiometricStatus.NOT_ENROLLED -> throw WrapperException(
                    Errors.EC_BIOMETRY_NOT_ENROLLED,
                    "No biometry enrolled on the device."
                )

                BiometricStatus.NOT_SUPPORTED -> throw WrapperException(
                    Errors.EC_BIOMETRY_NOT_SUPPORTED,
                    "Biometry is not supported on this device."
                )

                else -> throw WrapperException(
                    Errors.EC_BIOMETRY_NOT_AVAILABLE,
                    "Biometry check failed with status: $status"
                )
            }
        } else {
            throw WrapperException(
                Errors.EC_BIOMETRY_NOT_SUPPORTED,
                "Biometry requires Android 6.0 (API 23) or higher"
            )
        }
    }

    @KeychainProtection
    fun getKeychainProtectionFromString(stringValue: String?): Int {
        return when (stringValue) {
            "none" -> KeychainProtection.NONE
            "software" -> KeychainProtection.SOFTWARE
            "hardware" -> KeychainProtection.HARDWARE
            "strongbox" -> KeychainProtection.STRONGBOX
            else -> KeychainProtection.NONE
        }
    }

    @Throws(WrapperException::class)
    fun validateFragmentActivity(activity: Activity?): FragmentActivity {
        if (activity == null) {
            throw WrapperException(
                Errors.EC_FLUTTER_ERROR,
                "FragmentActivity is not available for biometry."
            )
        }

        if (activity !is FragmentActivity) {
            throw WrapperException(
                Errors.EC_FLUTTER_ERROR,
                "Attached Android Activity is not a FragmentActivity, which is required for biometry."
            )
        }

        return activity
    }
}
