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

import com.wultra.android.powerauth.flutter.Errors
import com.wultra.android.powerauth.flutter.WrapperException
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthService.ArgKeys.AUTHENTICATE_ON_BIOMETRIC_KEY_SETUP
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthService.ArgKeys.ALGORITHM
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthService.ArgKeys.BASIC_HTTP_AUTHENTICATION
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthService.ArgKeys.BASE_ENDPOINT_URL
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthService.ArgKeys.CONNECTION_TIMEOUT
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthService.ArgKeys.CONFIGURATION_STRING
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthService.ArgKeys.CONFIRM_BIOMETRIC_AUTHENTICATION
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthService.ArgKeys.CUSTOM_HTTP_HEADERS
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthService.ArgKeys.ENABLE_UNSECURE_TRAFFIC
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthService.ArgKeys.FALLBACK_TO_DEVICE_PASSCODE
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthService.ArgKeys.FALLBACK_TO_SHARED_BIOMETRY_KEY
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthService.ArgKeys.INVALIDATE_BIOMETRIC_FACTOR_AFTER_CHANGE
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthService.ArgKeys.MINIMAL_REQUIRED_KEYCHAIN_PROTECTION
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthService.ArgKeys.NAME
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthService.ArgKeys.OFFLINE_AUTHENTICATION_CODE_COMPONENT_LENGTH
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthService.ArgKeys.PASSWORD
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthService.ArgKeys.READ_TIMEOUT
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthService.ArgKeys.USERNAME
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthService.ArgKeys.USE_LEGACY_SYMMETRIC_KEY
import com.wultra.android.powerauth.flutter.internal.utils.PowerAuthAlgorithmUtils.algorithmFromString
import com.wultra.android.powerauth.flutter.internal.utils.PowerAuthAlgorithmUtils.algorithmToString
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthService.ArgKeys.VALUE
import com.wultra.android.powerauth.flutter.internal.utils.PowerAuthBiometryUtils.getKeychainProtectionFromString
import com.wultra.android.powerauth.flutter.internal.utils.PowerAuthBiometryUtils.keychainProtectionToString
import io.getlime.security.powerauth.networking.interceptors.BasicHttpAuthenticationRequestInterceptor
import io.getlime.security.powerauth.networking.interceptors.CustomHeaderRequestInterceptor
import io.getlime.security.powerauth.networking.ssl.HttpClientSslNoValidationStrategy
import io.getlime.security.powerauth.sdk.PowerAuthClientConfiguration
import io.getlime.security.powerauth.sdk.PowerAuthBiometricConfiguration
import io.getlime.security.powerauth.sdk.PowerAuthConfiguration
import io.getlime.security.powerauth.sdk.PowerAuthKeychainConfiguration

object PowerAuthConfigurationUtils {

    fun buildPowerAuthConfiguration(
        instanceId: String,
        map: Map<String, Any>
    ): PowerAuthConfiguration {
        val baseEndpointUrl = map[BASE_ENDPOINT_URL] as? String
            ?: throw WrapperException(
                Errors.EC_WRONG_PARAMETER,
                "Missing '$BASE_ENDPOINT_URL' in configuration map"
            )
        val configurationString = map[CONFIGURATION_STRING] as? String
            ?: throw WrapperException(
                Errors.EC_WRONG_PARAMETER,
                "Missing '$CONFIGURATION_STRING' string in configuration map"
            )

        val builder = PowerAuthConfiguration.Builder(instanceId, baseEndpointUrl, configurationString)
        (map[ALGORITHM] as? String)?.let { algorithm ->
            builder.algorithm(algorithmFromString(algorithm))
        }
        (map[OFFLINE_AUTHENTICATION_CODE_COMPONENT_LENGTH] as? Int)?.let { length ->
            builder.offlineAuthenticationCodeComponentLength(length)
        }
        return builder.build()
    }

    fun buildPowerAuthClientConfiguration(clientConfigMap: Map<String, Any>?): PowerAuthClientConfiguration {
        val builder = PowerAuthClientConfiguration.Builder()

        clientConfigMap?.let { map ->
            val enableUnsecure = (map[ENABLE_UNSECURE_TRAFFIC] as? Boolean)
                ?: PowerAuthClientConfiguration.DEFAULT_ALLOW_UNSECURED_CONNECTION

            if (enableUnsecure) {
                builder.clientValidationStrategy(HttpClientSslNoValidationStrategy())
                builder.allowUnsecuredConnection(true)
            }

            val connectionTimeoutMs =
                (map[CONNECTION_TIMEOUT] as? Double)?.let { (it * 1000).toInt() }
                    ?: PowerAuthClientConfiguration.DEFAULT_CONNECTION_TIMEOUT
            val readTimeoutMs = (map[READ_TIMEOUT] as? Double)?.let { (it * 1000).toInt() }
                ?: PowerAuthClientConfiguration.DEFAULT_READ_TIMEOUT

            builder.timeouts(connectionTimeoutMs, readTimeoutMs)

            @Suppress("UNCHECKED_CAST")
            (map[CUSTOM_HTTP_HEADERS] as? List<Map<String, String>>)?.forEach { headerMap ->
                val name = headerMap[NAME]
                val value = headerMap[VALUE]

                if (name != null && value != null) {
                    builder.requestInterceptor(CustomHeaderRequestInterceptor(name, value))
                }
            }

            @Suppress("UNCHECKED_CAST")
            (map[BASIC_HTTP_AUTHENTICATION] as? Map<String, String>)?.let { authMap ->
                val username = authMap[USERNAME]
                val password = authMap[PASSWORD]

                if (username != null && password != null) {
                    builder.requestInterceptor(
                        BasicHttpAuthenticationRequestInterceptor(
                            username,
                            password
                        )
                    )
                }
            }
        }

        return builder.build()
    }

    fun buildPowerAuthBiometricConfiguration(
        biometryMap: Map<String, Any>?
    ): PowerAuthBiometricConfiguration {
        val builder = PowerAuthBiometricConfiguration.Builder()
        biometryMap?.let {
            (it[INVALIDATE_BIOMETRIC_FACTOR_AFTER_CHANGE] as? Boolean)?.let { v ->
                builder.invalidateBiometricFactorAfterChange(
                    v
                )
            }
            (it[CONFIRM_BIOMETRIC_AUTHENTICATION] as? Boolean)?.let { v ->
                builder.confirmBiometricAuthentication(
                    v
                )
            }
            (it[AUTHENTICATE_ON_BIOMETRIC_KEY_SETUP] as? Boolean)?.let { v ->
                builder.authenticateOnBiometricKeySetup(
                    v
                )
            }
            (it[FALLBACK_TO_SHARED_BIOMETRY_KEY] as? Boolean)?.let { v ->
                builder.enableFallbackToSharedBiometryKey(
                    v
                )
            }
            (it[USE_LEGACY_SYMMETRIC_KEY] as? Boolean)?.let { v ->
                builder.useLegacySymmetricKey(
                    v
                )
            }
        }

        return builder.build()
    }

    fun buildPowerAuthKeychainConfiguration(
        keychainMap: Map<String, Any>?
    ): PowerAuthKeychainConfiguration {
        val builder = PowerAuthKeychainConfiguration.Builder()

        keychainMap?.let {
            (it[MINIMAL_REQUIRED_KEYCHAIN_PROTECTION] as? String)?.let { v ->
                builder.minimalRequiredKeychainProtection(getKeychainProtectionFromString(v))
            }
        }

        return builder.build()
    }

    fun configurationToMap(configuration: PowerAuthConfiguration): Map<String, Any?> {
        return mapOf(
            BASE_ENDPOINT_URL to configuration.baseEndpointUrl,
            CONFIGURATION_STRING to configuration.configuration,
            ALGORITHM to algorithmToString(configuration.algorithm),
            OFFLINE_AUTHENTICATION_CODE_COMPONENT_LENGTH to configuration.offlineAuthenticationCodeComponentLength
        )
    }

    fun clientConfigurationToMap(config: PowerAuthClientConfiguration): Map<String, Any> {
        return mapOf(
            ENABLE_UNSECURE_TRAFFIC to config.isUnsecuredConnectionAllowed,
            CONNECTION_TIMEOUT to config.connectionTimeout / 1000.0,
            READ_TIMEOUT to config.readTimeout / 1000.0
        )
    }

    fun biometryConfigurationToMap(config: PowerAuthBiometricConfiguration): Map<String, Any> {
        return mapOf(
            INVALIDATE_BIOMETRIC_FACTOR_AFTER_CHANGE to config.isInvalidateBiometricFactorAfterChange,
            // Device passcode fallback is supported only on Apple platforms.
            FALLBACK_TO_DEVICE_PASSCODE to false,
            CONFIRM_BIOMETRIC_AUTHENTICATION to config.isConfirmBiometricAuthentication,
            AUTHENTICATE_ON_BIOMETRIC_KEY_SETUP to config.isAuthenticateOnBiometricKeySetup,
            FALLBACK_TO_SHARED_BIOMETRY_KEY to config.isFallbackToSharedBiometryKeyEnabled,
            USE_LEGACY_SYMMETRIC_KEY to config.isUseLegacySymmetricKeyType
        )
    }

    fun keychainConfigurationToMap(config: PowerAuthKeychainConfiguration): Map<String, Any> {
        return mapOf(
            MINIMAL_REQUIRED_KEYCHAIN_PROTECTION to
                keychainProtectionToString(config.minimalRequiredKeychainProtection)
        )
    }
}
