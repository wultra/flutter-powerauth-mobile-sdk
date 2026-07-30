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

import androidx.fragment.app.FragmentActivity
import com.wultra.android.powerauth.flutter.Errors
import com.wultra.android.powerauth.flutter.WrapperException
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthService.ArgKeys.PROMPT_MESSAGE
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthService.ArgKeys.PROMPT_SUBTITLE
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthService.ArgKeys.PROMPT_TITLE
import io.getlime.security.powerauth.biometry.BiometricStatus
import io.getlime.security.powerauth.biometry.BiometryType
import io.getlime.security.powerauth.keychain.KeychainProtection
import io.getlime.security.powerauth.sdk.PowerAuthBiometricPrompt
import io.getlime.security.powerauth.sdk.PowerAuthBiometricStatus

object PowerAuthBiometryUtils {

    fun biometricStatusToMap(status: PowerAuthBiometricStatus): Map<String, Any> {
        val systemStatus = when (status.systemStatus) {
            BiometricStatus.OK -> "ok"
            BiometricStatus.NOT_ENROLLED -> "notEnrolled"
            BiometricStatus.NOT_AVAILABLE -> "notAvailable"
            BiometricStatus.NOT_SUPPORTED -> "notSupported"
            else -> "notSupported"
        }

        val biometryType = when (status.biometryType) {
            BiometryType.NONE -> "none"
            BiometryType.FINGERPRINT -> "fingerprint"
            BiometryType.FACE -> "face"
            BiometryType.IRIS -> "iris"
            BiometryType.GENERIC -> "generic"
            else -> "generic"
        }

        return mapOf(
            "isAuthenticationWithBiometricsAvailable" to status.isAuthenticationWithBiometricsAvailable,
            "isBiometricFactorConfigured" to status.isBiometricFactorConfigured,
            "systemStatus" to systemStatus,
            "biometryType" to biometryType
        )
    }

    fun buildBiometricPrompt(
        activity: FragmentActivity,
        promptMap: Map<String, Any>?,
        allowNoPrompt: Boolean,
        authenticateOnBiometricKeySetup: Boolean = true
    ): PowerAuthBiometricPrompt {
        if (promptMap == null) {
            if (allowNoPrompt && !authenticateOnBiometricKeySetup) {
                return PowerAuthBiometricPrompt.noPromptForBiometricKeySetup(activity)
            }
            throw WrapperException(
                Errors.EC_WRONG_PARAMETER,
                if (allowNoPrompt) {
                    "Biometric prompt is required when authenticateOnBiometricKeySetup is enabled."
                } else {
                    "Biometric prompt is required for biometric authentication."
                }
            )
        }

        val title = (promptMap[PROMPT_TITLE] as? String)?.takeIf { it.isNotBlank() }
            ?: throw WrapperException(
                Errors.EC_WRONG_PARAMETER,
                "Biometric prompt title is required on Android."
            )
        val message = (promptMap[PROMPT_MESSAGE] as? String)?.takeIf { it.isNotBlank() }
            ?: throw WrapperException(
                Errors.EC_WRONG_PARAMETER,
                "Biometric prompt message is required on Android."
            )

        val builder = PowerAuthBiometricPrompt.Builder(activity)
            .setTitle(title)
            .setDescription(message)
        (promptMap[PROMPT_SUBTITLE] as? String)?.takeIf { it.isNotBlank() }?.let {
            builder.setSubtitle(it)
        }
        return builder.build()
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

    fun keychainProtectionToString(@KeychainProtection protection: Int): String {
        return when (protection) {
            KeychainProtection.NONE -> "none"
            KeychainProtection.SOFTWARE -> "software"
            KeychainProtection.HARDWARE -> "hardware"
            KeychainProtection.STRONGBOX -> "strongbox"
            else -> throw WrapperException(
                Errors.EC_INVALID_NATIVE_OBJECT,
                "Unknown native keychain protection level: $protection"
            )
        }
    }

    @Throws(WrapperException::class)
    fun validateFragmentActivity(activity: FragmentActivity?): FragmentActivity {
        if (activity == null) {
            throw WrapperException(
                Errors.EC_FLUTTER_ERROR,
                "FragmentActivity is not available for biometry."
            )
        }

        return activity
    }
}
