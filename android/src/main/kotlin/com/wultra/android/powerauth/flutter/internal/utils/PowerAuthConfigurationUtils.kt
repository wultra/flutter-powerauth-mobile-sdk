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
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthService.ArgKeys.BASE_ENDPOINT_URL
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthService.ArgKeys.CONFIGURATION_STRING
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthService.ArgKeys.CONFIRM_BIOMETRIC_AUTHENTICATION
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthService.ArgKeys.FALLBACK_TO_SHARED_BIOMETRY_KEY
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthService.ArgKeys.LINK_ITEMS_TO_CURRENT_SET
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthService.ArgKeys.MINIMAL_REQUIRED_KEYCHAIN_PROTECTION
import com.wultra.android.powerauth.flutter.internal.utils.PowerAuthBiometryUtils.getKeychainProtectionFromString
import io.getlime.security.powerauth.networking.interceptors.BasicHttpAuthenticationRequestInterceptor
import io.getlime.security.powerauth.networking.interceptors.CustomHeaderRequestInterceptor
import io.getlime.security.powerauth.networking.ssl.HttpClientSslNoValidationStrategy
import io.getlime.security.powerauth.sdk.PowerAuthClientConfiguration
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

        return PowerAuthConfiguration.Builder(instanceId, baseEndpointUrl, configurationString)
            .build()
    }

    fun buildPowerAuthClientConfiguration(clientConfigMap: Map<String, Any>?): PowerAuthClientConfiguration {
        val builder = PowerAuthClientConfiguration.Builder()

        clientConfigMap?.let { map ->
            val enableUnsecure = (map["enableUnsecureTraffic"] as? Boolean)
                ?: PowerAuthClientConfiguration.DEFAULT_ALLOW_UNSECURED_CONNECTION

            if (enableUnsecure) {
                builder.clientValidationStrategy(HttpClientSslNoValidationStrategy())
                builder.allowUnsecuredConnection(true)
            }

            val connectionTimeoutMs =
                (map["connectionTimeout"] as? Double)?.let { (it * 1000).toInt() }
                    ?: PowerAuthClientConfiguration.DEFAULT_CONNECTION_TIMEOUT
            val readTimeoutMs = (map["readTimeout"] as? Double)?.let { (it * 1000).toInt() }
                ?: PowerAuthClientConfiguration.DEFAULT_READ_TIMEOUT

            builder.timeouts(connectionTimeoutMs, readTimeoutMs)

            @Suppress("UNCHECKED_CAST")
            (map["customHttpHeaders"] as? List<Map<String, String>>)?.forEach { headerMap ->
                val name = headerMap["name"]
                val value = headerMap["value"]

                if (name != null && value != null) {
                    builder.requestInterceptor(CustomHeaderRequestInterceptor(name, value))
                }
            }

            @Suppress("UNCHECKED_CAST")
            (map["basicHttpAuthentication"] as? Map<String, String>)?.let { authMap ->
                val username = authMap["username"]
                val password = authMap["password"]

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

    fun buildPowerAuthKeychainConfiguration(
        keychainMap: Map<String, Any>?,
        biometryMap: Map<String, Any>?
    ): PowerAuthKeychainConfiguration {
        val builder = PowerAuthKeychainConfiguration.Builder()

        biometryMap?.let {
            (it[LINK_ITEMS_TO_CURRENT_SET] as? Boolean)?.let { v ->
                builder.linkBiometricItemsToCurrentSet(
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
        }

        keychainMap?.let {
            (it[MINIMAL_REQUIRED_KEYCHAIN_PROTECTION] as? String)?.let { v ->
                builder.minimalRequiredKeychainProtection(getKeychainProtectionFromString(v))
            }
        }

        return builder.build()
    }
}
