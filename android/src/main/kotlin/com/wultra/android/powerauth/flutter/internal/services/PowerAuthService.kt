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
import android.os.Build
import android.util.Base64

import com.wultra.android.powerauth.flutter.PowerAuthObjectRegister
import com.wultra.android.powerauth.flutter.internal.core.BasePowerAuthService
import com.wultra.android.powerauth.flutter.internal.utils.PowerAuthLogger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import io.getlime.security.powerauth.biometry.*
import io.getlime.security.powerauth.core.*
import io.getlime.security.powerauth.exception.*
import io.getlime.security.powerauth.networking.response.*
import io.getlime.security.powerauth.sdk.*
import io.getlime.security.powerauth.core.Password
import io.getlime.security.powerauth.exception.PowerAuthErrorException
import io.getlime.security.powerauth.exception.PowerAuthErrorCodes

import androidx.core.util.component1
import androidx.core.util.component2
import androidx.fragment.app.FragmentActivity
import com.wultra.android.powerauth.flutter.Constants
import com.wultra.android.powerauth.flutter.Errors
import com.wultra.android.powerauth.flutter.ManagedAny
import com.wultra.android.powerauth.flutter.ReleasePolicy
import com.wultra.android.powerauth.flutter.WrapperException
import com.wultra.android.powerauth.flutter.internal.utils.PowerAuthActivationUtils.activationStatusToMap
import com.wultra.android.powerauth.flutter.internal.utils.PowerAuthActivationUtils.authorizationHeaderToMap
import com.wultra.android.powerauth.flutter.internal.utils.PowerAuthActivationUtils.createActivationResultToMap
import com.wultra.android.powerauth.flutter.internal.utils.PowerAuthBiometryUtils.extractPromptStrings
import com.wultra.android.powerauth.flutter.internal.utils.PowerAuthBiometryUtils.getBiometryInfo
import com.wultra.android.powerauth.flutter.internal.utils.PowerAuthBiometryUtils.validateBiometryBeforeUse
import com.wultra.android.powerauth.flutter.internal.utils.PowerAuthBiometryUtils.validateFragmentActivity
import com.wultra.android.powerauth.flutter.internal.utils.PowerAuthConfigurationUtils.buildPowerAuthClientConfiguration
import com.wultra.android.powerauth.flutter.internal.utils.PowerAuthConfigurationUtils.buildPowerAuthConfiguration
import com.wultra.android.powerauth.flutter.internal.utils.PowerAuthConfigurationUtils.buildPowerAuthKeychainConfiguration
import com.wultra.android.powerauth.flutter.internal.utils.PowerAuthConfigurationUtils.configurationToMap
import io.getlime.security.powerauth.networking.response.IGetTokenListener
import io.getlime.security.powerauth.networking.response.IRemoveTokenListener
import io.getlime.security.powerauth.sdk.PowerAuthToken
import java.nio.charset.StandardCharsets

internal class PowerAuthService(
    val objectRegister: PowerAuthObjectRegister,
    private val context: Context,
    private val getCurrentActivity: () -> FragmentActivity?
) : BasePowerAuthService(objectRegister) {

    override val name = "powerauth"

    companion object ArgKeys {
        const val INSTANCE_ID = "instanceId"
        const val CONFIGURATION = "configuration"
        const val CLIENT_CONFIGURATION = "clientConfiguration"
        const val BIOMETRY_CONFIGURATION = "biometryConfiguration"
        const val KEYCHAIN_CONFIGURATION = "keychainConfiguration"
        const val SHARING_CONFIGURATION = "sharingConfiguration"
        const val ACTIVATION = "activation"
        const val AUTHENTICATION = "authentication"
        const val PASSWORD = "password"
        const val OLD_PASSWORD = "oldPassword"
        const val NEW_PASSWORD = "newPassword"
        const val URI_ID = "uriId"
        const val QUERY_PARAMS = "queryParams"
        const val METHOD = "method"
        const val BODY = "body"
        const val NONCE = "nonce"
        const val DATA = "data"
        const val SIGNATURE = "signature"
        const val USE_MASTER_KEY = "useMasterKey"
        const val ACTIVATION_CODE = "activationCode"
        const val PROMPT = "prompt"
        const val BIOMETRIC_PROMPT = "biometricPrompt"
        const val ACTIVATION_NAME = "activationName"
        const val IDENTITY_ATTRIBUTES = "identityAttributes"
        const val EXTRAS = "extras"
        const val ADDITIONAL_ACTIVATION_OTP = "additionalActivationOtp"
        const val CUSTOM_ATTRIBUTES = "customAttributes"
        const val IS_BIOMETRY = "isBiometry"
        const val PROMPT_MESSAGE = "promptMessage"
        const val PROMPT_TITLE = "promptTitle"
        const val LINK_ITEMS_TO_CURRENT_SET = "linkItemsToCurrentSet"
        const val CONFIRM_BIOMETRIC_AUTHENTICATION = "confirmBiometricAuthentication"
        const val AUTHENTICATE_ON_BIOMETRIC_KEY_SETUP = "authenticateOnBiometricKeySetup"
        const val FALLBACK_TO_SHARED_BIOMETRY_KEY = "fallbackToSharedBiometryKey"
        const val MINIMAL_REQUIRED_KEYCHAIN_PROTECTION = "minimalRequiredKeychainProtection"
        const val BIOMETRY_KEY_ID = "biometryKeyId"
        const val BASE_ENDPOINT_URL = "baseEndpointUrl"
        const val CONFIGURATION_STRING = "configuration"
        const val OBJECT_ID = "objectId"
        const val TOKEN_NAME = "tokenName"
        const val OIDC_PARAMETERS = "oidcParameters"
    }

    private object HandlerNames {
        const val CONFIGURE = "configure"
        const val IS_CONFIGURED = "isConfigured"
        const val GET_CONFIGURATION = "getConfiguration"
        //TODO: implement when SDK 2.0.0 is available
        // const val GET_CLIENT_CONFIGURATION = "getClientConfiguration"
        // const val GET_BIOMETRY_CONFIGURATION = "getBiometryConfiguration"
        // const val GET_KEYCHAIN_CONFIGURATION = "getKeychainConfiguration"
        // const val GET_SHARING_CONFIGURATION = "getSharingConfiguration"
        const val DECONFIGURE = "deconfigure"
        const val HAS_VALID_ACTIVATION = "hasValidActivation"
        const val CAN_START_ACTIVATION = "canStartActivation"
        const val HAS_PENDING_ACTIVATION = "hasPendingActivation"
        const val GET_ACTIVATION_IDENTIFIER = "getActivationIdentifier"
        const val GET_ACTIVATION_FINGERPRINT = "getActivationFingerprint"
        const val FETCH_ACTIVATION_STATUS = "fetchActivationStatus"
        const val REMOVE_ACTIVATION_LOCAL = "removeActivationLocal"
        const val REMOVE_ACTIVATION_WITH_AUTHENTICATION = "removeActivationWithAuthentication"
        const val CREATE_ACTIVATION = "createActivation"
        const val PERSIST_ACTIVATION = "persistActivation"
        const val VALIDATE_PASSWORD = "validatePassword"
        const val CHANGE_PASSWORD = "changePassword"
        const val REQUEST_GET_SIGNATURE = "requestGetSignature"
        const val REQUEST_SIGNATURE = "requestSignature"
        const val OFFLINE_SIGNATURE = "offlineSignature"
        const val VERIFY_SERVER_SIGNED_DATA = "verifyServerSignedData"
        const val GET_BIOMETRY_INFO = "getBiometryInfo"
        const val ADD_BIOMETRY_FACTOR = "addBiometryFactor"
        const val HAS_BIOMETRY_FACTOR = "hasBiometryFactor"
        const val REMOVE_BIOMETRY_FACTOR = "removeBiometryFactor"
        const val AUTHENTICATE_WITH_BIOMETRY = "authenticateWithBiometry"
        const val REQUEST_ACCESS_TOKEN = "requestAccessToken"
        const val REMOVE_ACCESS_TOKEN = "removeAccessToken"
        const val HAS_LOCAL_TOKEN = "hasLocalToken"
        const val GET_LOCAL_TOKEN = "getLocalToken"
        const val REMOVE_LOCAL_TOKEN = "removeLocalToken"
        const val REMOVE_ALL_LOCAL_TOKENS = "removeAllLocalTokens"
        const val GENERATE_HEADER_FOR_TOKEN = "generateHeaderForToken"
        const val FETCH_ENCRYPTION_KEY = "fetchEncryptionKey"
        const val SIGN_DATA_WITH_DEVICE_PRIVATE_KEY = "signDataWithDevicePrivateKey"
        const val FETCH_USER_INFO = "fetchUserInfo"
        const val GET_LAST_FETCHED_USER_INFO = "getLastFetchedUserInfo"
        const val IS_TIME_SYNCHRONIZED = "isTimeSynchronized"
        const val LOCAL_TIME_ADJUSTMENT = "localTimeAdjustment"
        const val LOCAL_TIME_ADJUSTMENT_PRECISION = "localTimeAdjustmentPrecision"
        const val CURRENT_TIME = "currentTime"
        const val SYNCHRONIZE_TIME = "synchronizeTime"
        const val RESET_TIME_SYNCHRONIZATION = "resetTimeSynchronization"
        const val GET_EXTERNAL_PENDING_OPERATION = "getExternalPendingOperation"
    }

    override val handlers by lazy {
        mapOf(
            HandlerNames.CONFIGURE to this::configure,
            HandlerNames.IS_CONFIGURED to this::isConfigured,
            HandlerNames.GET_CONFIGURATION to this::getConfiguration,
            //TODO: implement when SDK 2.0.0 is available
            // HandlerNames.GET_CLIENT_CONFIGURATION to this::getClientConfiguration,
            // HandlerNames.GET_BIOMETRY_CONFIGURATION to this::getBiometryConfiguration,
            // HandlerNames.GET_KEYCHAIN_CONFIGURATION to this::getKeychainConfiguration,
            // HandlerNames.GET_SHARING_CONFIGURATION to this::getSharingConfiguration,
            HandlerNames.DECONFIGURE to this::deconfigure,
            HandlerNames.HAS_VALID_ACTIVATION to this::hasValidActivation,
            HandlerNames.CAN_START_ACTIVATION to this::canStartActivation,
            HandlerNames.HAS_PENDING_ACTIVATION to this::hasPendingActivation,
            HandlerNames.GET_ACTIVATION_IDENTIFIER to this::getActivationIdentifier,
            HandlerNames.GET_ACTIVATION_FINGERPRINT to this::getActivationFingerprint,
            HandlerNames.FETCH_ACTIVATION_STATUS to this::fetchActivationStatus,
            HandlerNames.REMOVE_ACTIVATION_LOCAL to this::removeActivationLocal,
            HandlerNames.REMOVE_ACTIVATION_WITH_AUTHENTICATION to this::removeActivationWithAuthentication,
            HandlerNames.CREATE_ACTIVATION to this::createActivation,
            HandlerNames.PERSIST_ACTIVATION to this::persistActivation,
            HandlerNames.VALIDATE_PASSWORD to this::validatePassword,
            HandlerNames.CHANGE_PASSWORD to this::changePassword,
            HandlerNames.REQUEST_GET_SIGNATURE to this::requestGetSignature,
            HandlerNames.REQUEST_SIGNATURE to this::requestSignature,
            HandlerNames.OFFLINE_SIGNATURE to this::offlineSignature,
            HandlerNames.VERIFY_SERVER_SIGNED_DATA to this::verifyServerSignedData,
            HandlerNames.GET_BIOMETRY_INFO to this::getBiometryInfo,
            HandlerNames.ADD_BIOMETRY_FACTOR to this::addBiometryFactor,
            HandlerNames.HAS_BIOMETRY_FACTOR to this::hasBiometryFactor,
            HandlerNames.REMOVE_BIOMETRY_FACTOR to this::removeBiometryFactor,
            HandlerNames.AUTHENTICATE_WITH_BIOMETRY to this::authenticateWithBiometry,
            HandlerNames.REQUEST_ACCESS_TOKEN to this::requestAccessToken,
            HandlerNames.REMOVE_ACCESS_TOKEN to this::removeAccessToken,
            HandlerNames.HAS_LOCAL_TOKEN to this::hasLocalToken,
            HandlerNames.GET_LOCAL_TOKEN to this::getLocalToken,
            HandlerNames.REMOVE_LOCAL_TOKEN to this::removeLocalToken,
            HandlerNames.REMOVE_ALL_LOCAL_TOKENS to this::removeAllLocalTokens,
            HandlerNames.GENERATE_HEADER_FOR_TOKEN to this::generateHeaderForToken,
            HandlerNames.FETCH_ENCRYPTION_KEY to this::fetchEncryptionKey,
            HandlerNames.SIGN_DATA_WITH_DEVICE_PRIVATE_KEY to this::signDataWithDevicePrivateKey,
            HandlerNames.FETCH_USER_INFO to this::fetchUserInfo,
            HandlerNames.GET_LAST_FETCHED_USER_INFO to this::getLastFetchedUserInfo,
            HandlerNames.IS_TIME_SYNCHRONIZED to this::isTimeSynchronized,
            HandlerNames.LOCAL_TIME_ADJUSTMENT to this::localTimeAdjustment,
            HandlerNames.LOCAL_TIME_ADJUSTMENT_PRECISION to this::localTimeAdjustmentPrecision,
            HandlerNames.CURRENT_TIME to this::currentTime,
            HandlerNames.SYNCHRONIZE_TIME to this::synchronizeTime,
            HandlerNames.RESET_TIME_SYNCHRONIZATION to this::resetTimeSynchronization,
            HandlerNames.GET_EXTERNAL_PENDING_OPERATION to this::getExternalPendingOperation
        )
    }

    private fun configure(call: MethodCall, result: Result) {
        try {
            val instanceId: String = call.getRequiredArgument(INSTANCE_ID)

            val configurationMap: Map<String, Any> = call.getRequiredArgument(CONFIGURATION)
            val clientConfigMap = call.argument<Map<String, Any>>(CLIENT_CONFIGURATION)
            val biometryConfigMap = call.argument<Map<String, Any>>(BIOMETRY_CONFIGURATION)
            val keychainConfigMap = call.argument<Map<String, Any>>(KEYCHAIN_CONFIGURATION)

            @Suppress("UNUSED_VARIABLE")
            val sharingConfigMap = call.argument<Map<String, Any>>(SHARING_CONFIGURATION)

            val registered = registerPowerAuthInstance(instanceId) {
                val powerAuthConfiguration =
                    buildPowerAuthConfiguration(instanceId, configurationMap)
                val clientConfiguration = buildPowerAuthClientConfiguration(clientConfigMap)
                val keychainConfiguration =
                    buildPowerAuthKeychainConfiguration(keychainConfigMap, biometryConfigMap)

                val sdkBuilder = PowerAuthSDK.Builder(powerAuthConfiguration)
                    .clientConfiguration(clientConfiguration)
                    .keychainConfiguration(keychainConfiguration)

                val sdk = sdkBuilder.build(context)

                return@registerPowerAuthInstance ManagedAny.wrap(sdk)
            }

            if (registered) {
                result.success(null)
            } else {
                throw WrapperException(
                    Errors.EC_WRONG_PARAMETER,
                    "PowerAuth instance '$instanceId' is already configured or registration failed."
                )
            }
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun isConfigured(call: MethodCall, result: Result) {
        try {
            val instanceId: String = call.getRequiredArgument(INSTANCE_ID)
            result.success(getPowerAuthInstance(instanceId) != null)
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun getConfiguration(call: MethodCall, result: Result) {
        usePowerAuth(call, result) { sdk ->
            val configuration = sdk.getConfiguration()
            result.success(configurationToMap(configuration))
        }
    }
    //TODO: Add other configurations when SDK 2.0.0 is available
    // private fun getClientConfiguration(call: MethodCall, result: Result) {
    //     usePowerAuth(call, result) { sdk ->
    //         val clientConfiguration = sdk.getClientConfiguration()
    //         result.success(configurationToMap(clientConfiguration))
    //     }
    // }
    //
    // private fun getBiometryConfiguration(call: MethodCall, result: Result) {
    //     usePowerAuth(call, result) { sdk ->
    //         val biometryConfiguration = sdk.getBiometryConfiguration()
    //         result.success(configurationToMap(biometryConfiguration))
    //     }
    // }
    //
    // private fun getKeychainConfiguration(call: MethodCall, result: Result) {
    //     usePowerAuth(call, result) { sdk ->
    //         val keychainConfiguration = sdk.getKeychainConfiguration()
    //         result.success(configurationToMap(keychainConfiguration))
    //     }
    // }
    //
    // private fun getSharingConfiguration(call: MethodCall, result: Result) {
    //     usePowerAuth(call, result) { sdk ->
    //         val sharingConfiguration = sdk.getSharingConfiguration()
    //         result.success(configurationToMap(sharingConfiguration))
    //     }
    // }

    private fun deconfigure(call: MethodCall, result: Result) {
        try {
            val instanceId: String = call.getRequiredArgument(INSTANCE_ID)
            unregisterPowerAuthInstance(instanceId)
            objectRegister.removeAllObjectsWithTag(instanceId)

            result.success(null)
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun hasValidActivation(call: MethodCall, result: Result) {
        usePowerAuth(call, result) { sdk ->
            result.success(sdk.hasValidActivation())
        }
    }

    private fun canStartActivation(call: MethodCall, result: Result) {
        usePowerAuth(call, result) { sdk ->
            result.success(sdk.canStartActivation())
        }
    }

    private fun hasPendingActivation(call: MethodCall, result: Result) {
        usePowerAuth(call, result) { sdk ->
            result.success(sdk.hasPendingActivation())
        }
    }

    private fun getActivationIdentifier(call: MethodCall, result: Result) {
        usePowerAuth(call, result) { sdk ->
            result.success(sdk.activationIdentifier)
        }
    }

    private fun getActivationFingerprint(call: MethodCall, result: Result) {
        usePowerAuth(call, result) { sdk ->
            result.success(sdk.activationFingerprint)
        }
    }

    private fun fetchActivationStatus(call: MethodCall, result: Result) {
        usePowerAuth(call, result) { sdk ->
            sdk.fetchActivationStatusWithCallback(context, object : IActivationStatusListener {
                override fun onActivationStatusSucceed(status: ActivationStatus) {
                    result.success(activationStatusToMap(status))
                }

                override fun onActivationStatusFailed(t: Throwable) {
                    Errors.error(result, t)
                }
            })
        }
    }

    private fun removeActivationLocal(call: MethodCall, result: Result) {
        usePowerAuth(call, result) { sdk ->
            sdk.removeActivationLocal(context)
            result.success(null)
        }
    }

    private fun removeActivationWithAuthentication(call: MethodCall, result: Result) {
        usePowerAuth(call, result) { sdk ->
            val authentication = buildAuthenticationObject(call, persist = false)

            sdk.removeActivationWithAuthentication(
                context,
                authentication,
                object : IActivationRemoveListener {
                    override fun onActivationRemoveSucceed() {
                        result.success(null)
                    }

                    override fun onActivationRemoveFailed(t: Throwable) {
                        Errors.error(result, t)
                    }
                })
        }
    }

    private fun createActivation(call: MethodCall, result: Result) {
        usePowerAuth(call, result) { sdk ->
            val activationMap: Map<String, Any> = call.getRequiredArgument(ACTIVATION)
            val activation = buildActivationObject(activationMap)

            sdk.createActivation(activation, object : ICreateActivationListener {
                override fun onActivationCreateSucceed(activationResult: CreateActivationResult) {
                    result.success(createActivationResultToMap(activationResult))
                }

                override fun onActivationCreateFailed(t: Throwable) {
                    Errors.error(result, t)
                }
            })
        }
    }

    private fun persistActivation(call: MethodCall, result: Result) {
        usePowerAuthOnMainThread(call, result) { sdk ->
            val authMap: Map<String, Any> = call.getRequiredArgument(AUTHENTICATION)
            val useBiometryActual = authMap[IS_BIOMETRY] as? Boolean ?: false

            val authenticationObject = buildAuthenticationObject(call, persist = true)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && useBiometryActual) {
                val corePassword = authenticationObject.password
                    ?: throw WrapperException(
                        Errors.EC_FLUTTER_ERROR,
                        "Password could not be retrieved from authentication object for biometric persist."
                    )

                val promptMap: Map<String, String>? =
                    authMap[BIOMETRIC_PROMPT] as? Map<String, String>
                val (title, description) = extractPromptStrings(promptMap)

                val activity = validateFragmentActivity(getCurrentActivity())

                sdk.persistActivation(
                    context,
                    activity,
                    title,
                    description,
                    corePassword,
                    object : IPersistActivationWithBiometricsListener {
                        override fun onBiometricDialogCancelled() {
                            Errors.error(
                                result,
                                PowerAuthErrorException(PowerAuthErrorCodes.BIOMETRY_CANCEL)
                            )
                        }

                        override fun onBiometricDialogSuccess() {
                            result.success(null)
                        }

                        override fun onBiometricDialogFailed(error: PowerAuthErrorException) {
                            Errors.error(result, error)
                        }
                    }
                )
            } else {
                val resultCode =
                    sdk.persistActivationWithAuthentication(context, authenticationObject)
                if (resultCode == PowerAuthErrorCodes.SUCCEED) {
                    result.success(null)
                } else {
                    Errors.error(result, PowerAuthErrorException(resultCode))
                }
            }
        }
    }

    private fun validatePassword(call: MethodCall, result: Result) {
        usePowerAuth(call, result) { sdk ->
            val passwordMap: Map<String, Any> = call.getRequiredArgument(PASSWORD)
            val password = buildPasswordObject(passwordMap, use = true)

            sdk.validatePassword(context, password, object : IValidatePasswordListener {
                override fun onPasswordValid() {
                    result.success(null)
                }

                override fun onPasswordValidationFailed(t: Throwable) {
                    Errors.error(result, t)
                }
            })
        }
    }

    private fun changePassword(call: MethodCall, result: Result) {
        usePowerAuth(call, result) { sdk ->
            val oldPasswordMap: Map<String, Any> = call.getRequiredArgument(OLD_PASSWORD)
            val newPasswordMap: Map<String, Any> = call.getRequiredArgument(NEW_PASSWORD)

            val oldPassword = buildPasswordObject(oldPasswordMap, use = true)
            val newPassword = buildPasswordObject(newPasswordMap, use = true)

            sdk.changePassword(context, oldPassword, newPassword, object : IChangePasswordListener {
                override fun onPasswordChangeSucceed() {
                    result.success(null)
                }

                override fun onPasswordChangeFailed(t: Throwable) {
                    Errors.error(result, t)
                }
            })
        }
    }

    private fun requestGetSignature(call: MethodCall, result: Result) {
        usePowerAuth(call, result) { sdk ->
            val authentication = buildAuthenticationObject(call, persist = false)
            val uriId: String = call.getRequiredArgument(URI_ID)
            val queryParams: Map<String, String>? = call.argument(QUERY_PARAMS)

            val header = sdk.requestGetSignatureWithAuthentication(
                context,
                authentication,
                uriId,
                queryParams
            )

            if (header.powerAuthErrorCode == PowerAuthErrorCodes.SUCCEED) {
                result.success(authorizationHeaderToMap(header))
            } else {
                throw PowerAuthErrorException(header.powerAuthErrorCode)
            }
        }
    }

    private fun requestSignature(call: MethodCall, result: Result) {
        usePowerAuth(call, result) { sdk ->
            val authentication = buildAuthenticationObject(call, persist = false)
            val method: String = call.getRequiredArgument(METHOD)
            val uriId: String = call.getRequiredArgument(URI_ID)
            val bodyString: String? = call.argument(BODY)
            val requestData: ByteArray? = bodyString?.toByteArray(Charsets.UTF_8)

            val header = sdk.requestSignatureWithAuthentication(
                context,
                authentication,
                method,
                uriId,
                requestData
            )

            if (header.powerAuthErrorCode == PowerAuthErrorCodes.SUCCEED) {
                result.success(authorizationHeaderToMap(header))
            } else {
                throw PowerAuthErrorException(header.powerAuthErrorCode)
            }
        }
    }

    private fun offlineSignature(call: MethodCall, result: Result) {
        usePowerAuth(call, result) { sdk ->
            val authentication = buildAuthenticationObject(call, persist = false)
            val uriId: String = call.getRequiredArgument(URI_ID)
            val nonce: String = call.getRequiredArgument(NONCE)
            val bodyString: String? = call.argument(BODY)
            val requestData: ByteArray? = bodyString?.toByteArray(Charsets.UTF_8)

            try {
                val signature = sdk.offlineSignatureWithAuthentication(
                    context,
                    authentication,
                    uriId,
                    requestData,
                    nonce
                )

                if (signature != null) {
                    result.success(signature)
                } else {
                    // TODO: tests required missing activation, however the SDK does not indicate and/or throw it
                    result.error(Errors.EC_MISSING_ACTIVATION, "Signature calculation failed", null)
                    // result.error(Errors.EC_SIGNATURE_ERROR, "Signature calculation failed", null)
                }
            } catch (e: PowerAuthMissingConfigException) {
                Errors.error(result, e)
            }
        }
    }

    private fun verifyServerSignedData(call: MethodCall, result: Result) {
        usePowerAuth(call, result) { sdk ->
            val dataString: String = call.getRequiredArgument(DATA)
            val signature: String = call.getRequiredArgument(SIGNATURE)
            val useMasterKey: Boolean = call.argument<Boolean>(USE_MASTER_KEY) ?: false

            val dataBytes = dataString.toByteArray()
            val signatureBytes = Base64.decode(signature, Base64.DEFAULT)

            val isValid = sdk.verifyServerSignedData(dataBytes, signatureBytes, useMasterKey)

            result.success(isValid)
        }
    }

    private fun addBiometryFactor(call: MethodCall, result: Result) {
        usePowerAuthOnMainThread(call, result) { sdk ->
            val passwordMap: Map<String, Any> = call.getRequiredArgument(PASSWORD)
            val promptMap: Map<String, Any>? = call.argument(PROMPT)
            val corePassword = buildPasswordObject(passwordMap, use = true)

            try {
                // validateBiometryBeforeUse(sdk)

                val activity = validateFragmentActivity(getCurrentActivity())

                val (title, description) = extractPromptStrings(promptMap)

                sdk.addBiometryFactor(
                    context,
                    activity,
                    title,
                    description,
                    corePassword,
                    object : IAddBiometryFactorListener {
                        override fun onAddBiometryFactorSucceed() {
                            result.success(null)
                        }

                        override fun onAddBiometryFactorFailed(error: PowerAuthErrorException) {
                            Errors.error(result, error)
                        }
                    }
                )
            } catch (e: Exception) {
                Errors.error(result, e)
            }
        }
    }

    private fun hasBiometryFactor(call: MethodCall, result: Result) {
        usePowerAuth(call, result) { sdk ->
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                result.success(sdk.hasBiometryFactor(context))
            } else {
                result.success(false)
            }
        }
    }

    private fun removeBiometryFactor(call: MethodCall, result: Result) {
        usePowerAuth(call, result) { sdk ->
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val removed = sdk.removeBiometryFactor(context)

                if (removed) {
                    result.success(null)
                } else {
                    if (!sdk.hasBiometryFactor(context)) {
                        throw WrapperException(
                            Errors.EC_BIOMETRY_NOT_CONFIGURED,
                            "Biometry factor was not configured."
                        )
                    } else {
                        throw WrapperException(
                            Errors.EC_FLUTTER_ERROR,
                            "Failed to remove biometry factor for unknown reason."
                        )
                    }
                }
            } else {
                throw WrapperException(
                    Errors.EC_BIOMETRY_NOT_SUPPORTED,
                    "Biometry requires Android 6.0 (API 23) or higher"
                )
            }
        }
    }

    private fun authenticateWithBiometry(call: MethodCall, result: Result) {
        usePowerAuthOnMainThread(call, result) { sdk ->
            val promptMap: Map<String, Any>? = call.argument(PROMPT)
            val instanceId: String = call.getRequiredArgument(INSTANCE_ID)

            try {
                validateBiometryBeforeUse(context, sdk)

                val activity = validateFragmentActivity(getCurrentActivity())
                val (title, description) = extractPromptStrings(promptMap)

                sdk.authenticateUsingBiometrics(
                    context,
                    activity,
                    title,
                    description,
                    object : IAuthenticateWithBiometricsListener {
                        override fun onBiometricDialogCancelled(userCancel: Boolean) {
                            Errors.error(
                                result,
                                PowerAuthErrorException(PowerAuthErrorCodes.BIOMETRY_CANCEL)
                            )
                        }

                        override fun onBiometricDialogSuccess(authentication: PowerAuthAuthentication) {
                            val key = authentication.biometryFactorRelatedKey
                            if (key == null) {
                                Errors.error(
                                    result,
                                    WrapperException(
                                        Errors.EC_FLUTTER_ERROR,
                                        "Biometric key missing after success."
                                    )
                                )
                                return
                            }

                            val managedKey = ManagedAny.wrap(key)
                            val keyId = objectRegister.registerObject(
                                managedKey,
                                instanceId,
                                listOf(
                                    ReleasePolicy.afterUse(1),
                                    ReleasePolicy.expire(Constants.BIOMETRY_KEY_KEEP_ALIVE_TIME)
                                )
                            )
                            result.success(keyId)
                        }

                        override fun onBiometricDialogFailed(error: PowerAuthErrorException) {
                            Errors.error(result, error)
                        }
                    }
                )
            } catch (e: Exception) {
                Errors.error(result, e)
            }
        }
    }

    private fun buildActivationObject(map: Map<String, Any>): PowerAuthActivation {
        val activationCode = map[ACTIVATION_CODE] as? String
        val identityAttributes = map[IDENTITY_ATTRIBUTES] as? Map<String, String>
        val name = map[ACTIVATION_NAME] as? String
        val oidcParameters = map[OIDC_PARAMETERS] as? Map<String, String>

        val activationBuilder = when {
            activationCode != null -> PowerAuthActivation.Builder.activation(activationCode, name)
            identityAttributes != null -> PowerAuthActivation.Builder.customActivation(
                identityAttributes,
                name
            )

            oidcParameters != null -> {
                val providerId = oidcParameters["providerId"] ?: throw WrapperException(
                    Errors.EC_INVALID_ACTIVATION_OBJECT,
                    "Missing providerId in oidcParameters"
                )
                val code = oidcParameters["code"] ?: throw WrapperException(
                    Errors.EC_INVALID_ACTIVATION_OBJECT,
                    "Missing code in oidcParameters"
                )
                val nonce = oidcParameters["nonce"] ?: throw WrapperException(
                    Errors.EC_INVALID_ACTIVATION_OBJECT,
                    "Missing nonce in oidcParameters"
                )
                val codeVerifier = oidcParameters["codeVerifier"]

                try {
                    PowerAuthActivation.Builder.oidcActivation(
                        providerId,
                        code,
                        nonce,
                        codeVerifier
                    )
                } catch (e: PowerAuthErrorException) {
                    throw WrapperException(
                        Errors.EC_INVALID_ACTIVATION_OBJECT,
                        "Invalid OIDC parameters provided"
                    )
                }


            }

            else -> throw WrapperException(
                Errors.EC_INVALID_ACTIVATION_OBJECT,
                "Missing activationCode, identityAttributes, or oidcParameters"
            )
        }

        (map[EXTRAS] as? String)?.let { activationBuilder.setExtras(it) }
        (map[ADDITIONAL_ACTIVATION_OTP] as? String)?.let {
            activationBuilder.setAdditionalActivationOtp(
                it
            )
        }
        (map[CUSTOM_ATTRIBUTES] as? Map<String, Any>)?.let {
            activationBuilder.setCustomAttributes(
                it
            )
        }

        return activationBuilder.build()
    }

    private fun buildAuthenticationObject(
        call: MethodCall,
        persist: Boolean
    ): PowerAuthAuthentication {
        val authMap: Map<String, Any> = call.getRequiredArgument(AUTHENTICATION)

        val useBiometry = authMap[IS_BIOMETRY] as? Boolean ?: false
        val passwordMap = authMap[PASSWORD] as? Map<String, Any>
        val biometryKeyId = authMap[BIOMETRY_KEY_ID] as? String

        val password: Password? = if (passwordMap != null) {
            buildPasswordObject(passwordMap, use = true)
        } else {
            null
        }

        return if (persist) {
            if (password == null) {
                throw WrapperException(
                    Errors.EC_WRONG_PARAMETER,
                    "Password is required for persisting activation."
                )
            }

            if (useBiometry) {
                val biometricKeyBytes = biometryKeyId?.let { keyId ->
                    objectRegister.useObject(keyId, ByteArray::class.java)
                        ?: throw WrapperException(
                            Errors.EC_INVALID_NATIVE_OBJECT,
                            "Biometric key for ID '$keyId' (from biometryKeyId) not found or expired. This key is required if biometryKeyId is explicitly provided for persisting."
                        )
                }

                if (biometricKeyBytes != null) {
                    PowerAuthAuthentication.persistWithPasswordAndBiometry(
                        password,
                        biometricKeyBytes
                    )
                } else {
                    PowerAuthAuthentication.persistWithPassword(password)
                }
            } else {
                PowerAuthAuthentication.persistWithPassword(password)
            }
        } else {
            val biometryKeyBytes = biometryKeyId?.let { keyId ->
                objectRegister.useObject(keyId, ByteArray::class.java)
                    ?: throw WrapperException(
                        Errors.EC_INVALID_NATIVE_OBJECT,
                        "Biometric key for ID '$keyId' (from biometryKeyId) not found or expired for signing."
                    )
            }

            if (biometryKeyBytes != null) {
                PowerAuthAuthentication.possessionWithBiometry(biometryKeyBytes)
            } else if (password != null) {
                PowerAuthAuthentication.possessionWithPassword(password)
            } else {
                PowerAuthAuthentication.possession()
            }
        }
    }

    private fun buildPasswordObject(passwordArgMap: Map<String, Any>, use: Boolean): Password {
        passwordArgMap[OBJECT_ID]?.let { objectIdValue ->
            if (objectIdValue is String) {
                val managedPassword = if (use) {
                    objectRegister.useObject(objectIdValue, Password::class.java)
                } else {
                    objectRegister.touchObject(objectIdValue, Password::class.java)
                }

                return managedPassword ?: throw WrapperException(
                    Errors.EC_INVALID_NATIVE_OBJECT,
                    "PowerAuthPassword object with ID '$objectIdValue' is no longer valid or not found."
                )
            }
        }

        throw WrapperException(
            Errors.EC_WRONG_PARAMETER,
            "Invalid password argument. Expected a map with 'objectId' string."
        )
    }

    @Throws(PowerAuthErrorException::class)
    private fun getPowerAuthInstance(instanceId: String): PowerAuthSDK? {
        if (!objectRegister.isValidObjectId(instanceId)) {
            throw PowerAuthErrorException(
                PowerAuthErrorCodes.WRONG_PARAMETER,
                "Instance ID is missing or invalid."
            )
        }

        return objectRegister.findObject(instanceId, PowerAuthSDK::class.java)
    }

    @Throws(Throwable::class)
    private fun registerPowerAuthInstance(
        instanceId: String,
        factory: PowerAuthObjectRegister.ObjectFactory<PowerAuthSDK>
    ): Boolean {
        if (!objectRegister.isValidObjectId(instanceId)) {
            throw PowerAuthErrorException(
                PowerAuthErrorCodes.WRONG_PARAMETER,
                "Instance ID is missing or invalid for registration."
            )
        }

        return objectRegister.registerObjectWithId(
            instanceId,
            instanceId,
            listOf(ReleasePolicy.manual()),
            factory
        )
    }

    @Throws(PowerAuthErrorException::class)
    private fun unregisterPowerAuthInstance(instanceId: String) {
        if (!objectRegister.isValidObjectId(instanceId)) {
            throw PowerAuthErrorException(
                PowerAuthErrorCodes.WRONG_PARAMETER,
                "Instance ID is missing or invalid for unregistration."
            )
        }

        objectRegister.removeAllObjectsWithTag(instanceId)
    }

    private fun requestAccessToken(call: MethodCall, result: Result) {
        val tokenName: String = call.getRequiredArgument(TOKEN_NAME)
        val authentication = buildAuthenticationObject(call, persist = false)

        usePowerAuth(call, result) { sdk ->
            sdk.tokenStore.requestAccessToken(
                context,
                tokenName,
                authentication,
                object : IGetTokenListener {
                    override fun onGetTokenSucceeded(token: PowerAuthToken) {
                        result.success(
                            mapOf(
                                "tokenName" to token.tokenName,
                                "tokenIdentifier" to token.tokenIdentifier
                            )
                        )
                    }

                    override fun onGetTokenFailed(t: Throwable) {
                        Errors.error(result, t)
                    }
                }
            )
        }
    }

    private fun removeAccessToken(call: MethodCall, result: Result) {
        val tokenName: String = call.getRequiredArgument(TOKEN_NAME)

        usePowerAuth(call, result) { sdk ->
            sdk.tokenStore.removeAccessToken(
                context,
                tokenName,
                object : IRemoveTokenListener {
                    override fun onRemoveTokenSucceeded() {
                        result.success(null)
                    }

                    override fun onRemoveTokenFailed(t: Throwable) {
                        Errors.error(result, t)
                    }
                })
        }
    }

    private fun hasLocalToken(call: MethodCall, result: Result) {
        val tokenName: String = call.getRequiredArgument(TOKEN_NAME)

        usePowerAuth(call, result) { sdk ->
            result.success(sdk.tokenStore.hasLocalToken(context, tokenName))
        }
    }

    private fun getLocalToken(call: MethodCall, result: Result) {
        val tokenName: String = call.getRequiredArgument(TOKEN_NAME)

        usePowerAuth(call, result) { sdk ->
            val token = sdk.tokenStore.getLocalToken(context, tokenName)

            if (token != null) {
                result.success(
                    mapOf(
                        "tokenName" to token.tokenName,
                        "tokenIdentifier" to token.tokenIdentifier
                    )
                )
            } else {
                result.error(
                    Errors.EC_LOCAL_TOKEN_NOT_AVAILABLE,
                    "Token with this name is not in the local store.",
                    null
                )
            }
        }
    }

    private fun removeLocalToken(call: MethodCall, result: Result) {
        val tokenName: String = call.getRequiredArgument(TOKEN_NAME)

        usePowerAuth(call, result) { sdk ->
            sdk.tokenStore.removeLocalToken(context, tokenName)
            result.success(null)
        }
    }

    private fun removeAllLocalTokens(call: MethodCall, result: Result) {
        usePowerAuth(call, result) { sdk ->
            sdk.tokenStore.removeAllLocalTokens(context)
            result.success(null)
        }
    }

    private fun generateHeaderForToken(call: MethodCall, result: Result) {
        val tokenName: String = call.getRequiredArgument(TOKEN_NAME)

        usePowerAuth(call, result) { sdk ->

            sdk.tokenStore.generateAuthorizationHeader(context, tokenName, object: IGenerateTokenHeaderListener {
                override fun onGenerateTokenHeaderSucceeded(header: PowerAuthAuthorizationHttpHeader) {
                    result.success(mapOf("key" to header.key, "value" to header.value))
                }

                override fun onGenerateTokenHeaderFailed(t: Throwable) {
                    result.error(
                        Errors.EC_CANNOT_GENERATE_TOKEN,
                        "Cannot generate header for this token.",
                        t
                    )
                }
            })
        }
    }

    private fun fetchEncryptionKey(call: MethodCall, result: Result) {
        val index: Int = call.getRequiredArgument("index")
        val authentication = buildAuthenticationObject(call, persist = false)

        usePowerAuth(call, result) { sdk ->
            sdk.fetchEncryptionKey(
                context,
                authentication,
                index.toLong(),
                object : IFetchEncryptionKeyListener {
                    override fun onFetchEncryptionKeySucceed(key: ByteArray) {
                        result.success(Base64.encodeToString(key, Base64.NO_WRAP))
                    }

                    override fun onFetchEncryptionKeyFailed(t: Throwable) {
                        Errors.error(result, t)
                    }
                }
            )
        }
    }

    private fun signDataWithDevicePrivateKey(call: MethodCall, result: Result) {
        val data: String = call.getRequiredArgument(DATA)
        val authentication = buildAuthenticationObject(call, persist = false)

        usePowerAuth(call, result) { sdk ->
            sdk.signDataWithDevicePrivateKey(
                context,
                authentication,
                data.toByteArray(StandardCharsets.UTF_8),
                object : IDataSignatureListener {
                    override fun onDataSignedSucceed(signature: ByteArray) {
                        result.success(Base64.encodeToString(signature, Base64.NO_WRAP))
                    }

                    override fun onDataSignedFailed(t: Throwable) {
                        Errors.error(result, t)
                    }
                }
            )
        }
    }

    private fun fetchUserInfo(call: MethodCall, result: Result) {
        usePowerAuth(call, result) { sdk ->
            sdk.fetchUserInfo(context, object : IUserInfoListener {
                override fun onUserInfoSucceed(userInfo: UserInfo) {
                    result.success(mapOf("allClaims" to userInfo.allClaims))
                }

                override fun onUserInfoFailed(t: Throwable) {
                    Errors.error(result, t)
                }
            })
        }
    }

    private fun getLastFetchedUserInfo(call: MethodCall, result: Result) {
        usePowerAuth(call, result) { sdk ->
            val userInfo = sdk.lastFetchedUserInfo
            if (userInfo != null) {
                result.success(mapOf("allClaims" to userInfo.allClaims))
            } else {
                result.success(null)
            }
        }
    }

    @Suppress("UNUSED_PARAMETER")
    private fun getBiometryInfo(call: MethodCall, result: Result) {
        getBiometryInfo(context, result)
    }

    private fun isTimeSynchronized(call: MethodCall, result: Result) {
        usePowerAuth(call, result) { sdk ->
            result.success(sdk.timeSynchronizationService.isTimeSynchronized)
        }
    }

    private fun localTimeAdjustment(call: MethodCall, result: Result) {
        usePowerAuth(call, result) { sdk ->
            // double is expected on the Flutter side
            result.success(sdk.timeSynchronizationService.localTimeAdjustment)
        }
    }

    private fun localTimeAdjustmentPrecision(call: MethodCall, result: Result) {
        usePowerAuth(call, result) { sdk ->
            // double is expected on the Flutter side
            result.success(sdk.timeSynchronizationService.localTimeAdjustmentPrecision)
        }
    }

    private fun currentTime(call: MethodCall, result: Result) {
        usePowerAuth(call, result) { sdk ->
            // double is expected on the Flutter side
            result.success(sdk.timeSynchronizationService.currentTime)
        }
    }

    private fun synchronizeTime(call: MethodCall, result: Result) {
        usePowerAuth(call, result) { sdk ->
            sdk.timeSynchronizationService.synchronizeTime(object : ITimeSynchronizationListener {
                override fun onTimeSynchronizationSucceeded() {
                    result.success(null)
                }

                override fun onTimeSynchronizationFailed(t: Throwable) {
                    Errors.error(result, t)
                }
            })
        }
    }

    private fun resetTimeSynchronization(call: MethodCall, result: Result) {
        usePowerAuth(call, result) { sdk ->
            sdk.timeSynchronizationService.resetTimeSynchronization()
            result.success(null)
        }
    }

    private fun getExternalPendingOperation(call: MethodCall, result: Result) {
        PowerAuthLogger.info { "The getExternalPendingOperationMethod is not implemented in the Android layer, as it is a iOS-only feature." }
        result.success(null)
    }
}
