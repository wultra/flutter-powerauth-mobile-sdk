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

import android.app.Activity
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Base64
import androidx.fragment.app.FragmentActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.getlime.security.powerauth.biometry.*
import io.getlime.security.powerauth.core.*
import io.getlime.security.powerauth.exception.*
import io.getlime.security.powerauth.networking.response.*
import io.getlime.security.powerauth.sdk.*
import io.getlime.security.powerauth.core.Password
import io.getlime.security.powerauth.exception.PowerAuthErrorException
import io.getlime.security.powerauth.exception.PowerAuthErrorCodes
import io.getlime.security.powerauth.keychain.KeychainProtection
import kotlin.collections.set

import android.util.Pair
import androidx.core.util.component1
import androidx.core.util.component2

// TODO: migrate method docs from RN
class PowerAuthPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel : MethodChannel
    private lateinit var context: Context
    private var currentActivity: Activity? = null
    private lateinit var objectRegister: PowerAuthObjectRegister

    companion object ArgKeys {
        const val INSTANCE_ID = "instanceId"
        const val CONFIGURATION = "configuration"
        const val BIOMETRY_CONFIGURATION = "biometryConfiguration"
        const val KEYCHAIN_CONFIGURATION = "keychainConfiguration"
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
        const val CHARACTER = "character"
        const val PROMPT = "prompt"
        const val ACTIVATION_SIGNATURE = "activationSignature"
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

        const val PASSWORD_DESTROY_ON_USE = "destroyOnUse"
        const val PASSWORD_AUTORELEASE_TIME = "autoreleaseTime"
        const val PASSWORD_OWNER_ID = "ownerId"
        const val PASSWORD_ID1 = "passwordId1"
        const val PASSWORD_ID2 = "passwordId2"
        const val PASSWORD_POSITION = "position"
    }

    private object MethodNames {
        const val GET_PLATFORM_VERSION = "getPlatformVersion"
        const val CONFIGURE = "configure"
        const val IS_CONFIGURED = "isConfigured"
        const val DECONFIGURE = "deconfigure"
        const val UTIL_PARSE_ACTIVATION_CODE = "util_parseActivationCode"
        const val UTIL_VALIDATE_ACTIVATION_CODE = "util_validateActivationCode"
        const val UTIL_VALIDATE_TYPED_CHARACTER = "util_validateTypedCharacter"
        const val UTIL_CORRECT_TYPED_CHARACTER = "util_correctTypedCharacter"
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

        const val PASSWORD_INITIALIZE = "password_initialize"
        const val PASSWORD_RELEASE = "password_release"
        const val PASSWORD_CLEAR = "password_clear"
        const val PASSWORD_LENGTH = "password_length"
        const val PASSWORD_IS_EQUAL = "password_isEqual"
        const val PASSWORD_ADD_CHARACTER = "password_addCharacter"
        const val PASSWORD_INSERT_CHARACTER = "password_insertCharacter"
        const val PASSWORD_REMOVE_CHARACTER_AT = "password_removeCharacterAt"
        const val PASSWORD_REMOVE_LAST_CHARACTER = "password_removeLastCharacter"
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "powerauth_plugin")
        channel.setMethodCallHandler(this)

        objectRegister = PowerAuthObjectRegister()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)

        // TODO(post-beta): Flutter can destroy / recreate the plugin object if the engine detaches.
        // This can happen f.e. with the back button press on the first screen (app keeps running, but plugins re-attach.
        // We should explore this more (and cache the state?).
        objectRegister.invalidate()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        currentActivity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        currentActivity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        currentActivity = binding.activity
    }

    override fun onDetachedFromActivity() {
        currentActivity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            MethodNames.GET_PLATFORM_VERSION -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
            MethodNames.CONFIGURE -> configure(call, result)
            MethodNames.IS_CONFIGURED -> isConfigured(call, result)
            MethodNames.DECONFIGURE -> deconfigure(call, result)
            MethodNames.UTIL_PARSE_ACTIVATION_CODE -> parseActivationCode(call, result)
            MethodNames.UTIL_VALIDATE_ACTIVATION_CODE -> validateActivationCode(call, result)
            MethodNames.UTIL_VALIDATE_TYPED_CHARACTER -> validateTypedCharacter(call, result)
            MethodNames.UTIL_CORRECT_TYPED_CHARACTER -> correctTypedCharacter(call, result)
            MethodNames.HAS_VALID_ACTIVATION -> hasValidActivation(call, result)
            MethodNames.CAN_START_ACTIVATION -> canStartActivation(call, result)
            MethodNames.HAS_PENDING_ACTIVATION -> hasPendingActivation(call, result)
            MethodNames.GET_ACTIVATION_IDENTIFIER -> getActivationIdentifier(call, result)
            MethodNames.GET_ACTIVATION_FINGERPRINT -> getActivationFingerprint(call, result)
            MethodNames.FETCH_ACTIVATION_STATUS -> fetchActivationStatus(call, result)
            MethodNames.REMOVE_ACTIVATION_LOCAL -> removeActivationLocal(call, result)
            MethodNames.REMOVE_ACTIVATION_WITH_AUTHENTICATION -> removeActivationWithAuthentication(call, result)
            MethodNames.CREATE_ACTIVATION -> createActivation(call, result)
            MethodNames.PERSIST_ACTIVATION -> persistActivation(call, result)
            MethodNames.VALIDATE_PASSWORD -> validatePassword(call, result)
            MethodNames.CHANGE_PASSWORD -> changePassword(call, result)
            MethodNames.REQUEST_GET_SIGNATURE -> requestGetSignature(call, result)
            MethodNames.REQUEST_SIGNATURE -> requestSignature(call, result)
            MethodNames.OFFLINE_SIGNATURE -> offlineSignature(call, result)
            MethodNames.VERIFY_SERVER_SIGNED_DATA -> verifyServerSignedData(call, result)
            MethodNames.GET_BIOMETRY_INFO -> getBiometryInfo(result)
            MethodNames.ADD_BIOMETRY_FACTOR -> addBiometryFactor(call, result)
            MethodNames.HAS_BIOMETRY_FACTOR -> hasBiometryFactor(call, result)
            MethodNames.REMOVE_BIOMETRY_FACTOR -> removeBiometryFactor(call, result)
            MethodNames.AUTHENTICATE_WITH_BIOMETRY -> authenticateWithBiometry(call, result)
            MethodNames.PASSWORD_INITIALIZE -> passwordInitialize(call, result)
            MethodNames.PASSWORD_RELEASE -> removeNativeObject(call, result)
            MethodNames.PASSWORD_CLEAR -> passwordClear(call, result)
            MethodNames.PASSWORD_LENGTH -> passwordLength(call, result)
            MethodNames.PASSWORD_IS_EQUAL -> passwordIsEqual(call, result)
            MethodNames.PASSWORD_ADD_CHARACTER -> passwordAddCharacter(call, result)
            MethodNames.PASSWORD_INSERT_CHARACTER -> passwordInsertCharacter(call, result)
            MethodNames.PASSWORD_REMOVE_CHARACTER_AT -> passwordRemoveCharacterAt(call, result)
            MethodNames.PASSWORD_REMOVE_LAST_CHARACTER -> passwordRemoveLastCharacter(call, result)
            else -> result.notImplemented()
        }
    }

    private fun usePowerAuth(call: MethodCall, result: Result, block: (sdk: PowerAuthSDK) -> Unit) {
        try {
            val instanceId: String = call.getRequiredArgument(INSTANCE_ID)
            val sdkForBlock = objectRegister.useObject(instanceId, PowerAuthSDK::class.java)
                ?: throw WrapperException(Errors.EC_INSTANCE_NOT_CONFIGURED, "PowerAuth instance '$instanceId' not configured or no longer valid.")

            block(sdkForBlock)
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun usePowerAuthOnMainThread(call: MethodCall, result: Result, block: (sdk: PowerAuthSDK) -> Unit) {
        Handler(Looper.getMainLooper()).post {
            try {
                val instanceId: String = call.getRequiredArgument(INSTANCE_ID)
                val sdkForBlock = objectRegister.useObject(instanceId, PowerAuthSDK::class.java)
                    ?: throw WrapperException(Errors.EC_INSTANCE_NOT_CONFIGURED, "PowerAuth instance '$instanceId' not configured or no longer valid.")

                block(sdkForBlock)
            } catch (t: Throwable) {
                Errors.error(result, t)
            }
        }
    }

    private fun configure(call: MethodCall, result: Result) {
        try {
            val instanceId: String = call.getRequiredArgument(INSTANCE_ID)
            val configurationMap: Map<String, Any> = call.getRequiredArgument(CONFIGURATION)
            val biometryConfigMap = call.argument<Map<String, Any>>(BIOMETRY_CONFIGURATION)
            val keychainConfigMap = call.argument<Map<String, Any>>(KEYCHAIN_CONFIGURATION)

            val registered = registerPowerAuthInstance(instanceId) {
                val powerAuthConfiguration = buildPowerAuthConfiguration(instanceId, configurationMap)
                val keychainConfiguration = buildPowerAuthKeychainConfiguration(keychainConfigMap, biometryConfigMap)

                val sdk = PowerAuthSDK.Builder(powerAuthConfiguration)
                    .keychainConfiguration(keychainConfiguration)
                    .build(context)

                return@registerPowerAuthInstance ManagedAny.wrap(sdk)
            }

            if (registered) {
                result.success(null)
            } else {
                throw WrapperException(Errors.EC_WRONG_PARAMETER, "PowerAuth instance '$instanceId' is already configured or registration failed.")
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

    private fun deconfigure(call: MethodCall, result: Result) {
        try {
            val instanceId: String = call.getRequiredArgument(INSTANCE_ID)
            unregisterPowerAuthInstance(instanceId)
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

            sdk.removeActivationWithAuthentication(context, authentication, object: IActivationRemoveListener {
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

            sdk.createActivation(activation, object: ICreateActivationListener {
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
        usePowerAuth(call, result) { sdk ->
            val authentication = buildAuthenticationObject(call, persist = true)
            val resultCode = sdk.persistActivationWithAuthentication(context, authentication)

            if (resultCode == PowerAuthErrorCodes.SUCCEED) {
                result.success(null)
            } else {
                throw PowerAuthErrorException(resultCode)
            }
        }
    }

    private fun validatePassword(call: MethodCall, result: Result) {
        usePowerAuth(call, result) { sdk ->
            val passwordMap: Map<String, Any> = call.getRequiredArgument(PASSWORD)
            val password = buildPasswordObject(passwordMap, use = true)

            sdk.validatePassword(context, password, object: IValidatePasswordListener {
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

            val oldPassword = buildPasswordObject(oldPasswordMap, use = false)
            val newPassword = buildPasswordObject(newPasswordMap, use = false)

            sdk.changePassword(context, oldPassword, newPassword, object: IChangePasswordListener {
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

            val header = sdk.requestGetSignatureWithAuthentication(context, authentication, uriId, queryParams)

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

            val header = sdk.requestSignatureWithAuthentication(context, authentication, method, uriId, requestData)

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

            val signature: String? =
                sdk.offlineSignatureWithAuthentication(context, authentication, uriId, requestData, nonce)

            if (signature != null) {
                result.success(signature)
            } else {
                result.error(Errors.EC_SIGNATURE_ERROR, "Signature calculation failed", null)
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

    private fun getBiometryInfo(result: Result) {
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

    private fun addBiometryFactor(call: MethodCall, result: Result) {
        usePowerAuthOnMainThread(call, result) { sdk ->
            val passwordMap: Map<String, Any> = call.getRequiredArgument(PASSWORD)
            val promptMap: Map<String, Any>? = call.argument(PROMPT)
            val corePassword = buildPasswordObject(passwordMap, use = true)

            try {
                // validateBiometryBeforeUse(sdk)

                val activity = currentActivity
                    ?: throw WrapperException(Errors.EC_FLUTTER_ERROR, "Android Activity is not available when attempting to add biometry factor.")

                if (activity !is FragmentActivity) {
                    throw WrapperException(Errors.EC_FLUTTER_ERROR, "Attached Android Activity is not a FragmentActivity, which is required for biometry.")
                }

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
                        throw WrapperException(Errors.EC_BIOMETRY_NOT_CONFIGURED, "Biometry factor was not configured.")
                    } else {
                        throw WrapperException(Errors.EC_FLUTTER_ERROR, "Failed to remove biometry factor for unknown reason.")
                    }
                }
            } else {
                throw WrapperException(Errors.EC_BIOMETRY_NOT_SUPPORTED, "Biometry requires Android 6.0 (API 23) or higher")
            }
        }
    }

    private fun authenticateWithBiometry(call: MethodCall, result: Result) {
        usePowerAuthOnMainThread(call, result) { sdk ->
            val promptMap: Map<String, Any>? = call.argument(PROMPT)
            val instanceId: String = call.getRequiredArgument(INSTANCE_ID)

            try {
                validateBiometryBeforeUse(sdk)

                val activity = currentActivity
                if (activity == null || activity !is FragmentActivity) {
                    throw WrapperException(Errors.EC_FLUTTER_ERROR, "FragmentActivity is not available for biometry.")
                }

                val (title, description) = extractPromptStrings(promptMap)

                sdk.authenticateUsingBiometrics(
                    context,
                    activity,
                    title,
                    description,
                    object : IAuthenticateWithBiometricsListener {
                        override fun onBiometricDialogCancelled(userCancel: Boolean) {
                            Errors.error(result, PowerAuthErrorException(PowerAuthErrorCodes.BIOMETRY_CANCEL))
                        }

                        override fun onBiometricDialogSuccess(authentication: PowerAuthAuthentication) {
                            val key = authentication.biometryFactorRelatedKey
                            if (key == null) {
                                Errors.error(result, WrapperException(Errors.EC_FLUTTER_ERROR, "Biometric key missing after success."))
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

    private fun parseActivationCode(call: MethodCall, result: Result) {
        try {
            val activationCodeString: String = call.getRequiredArgument(ACTIVATION_CODE)
            val ac: ActivationCode? = ActivationCodeUtil.parseFromActivationCode(activationCodeString)

            if (ac != null) {
                val response = mutableMapOf<String, String?>(
                    ACTIVATION_CODE to ac.activationCode
                )

                ac.activationSignature?.let { response[ACTIVATION_SIGNATURE] = it }

                result.success(response)
            } else {
                result.error(Errors.EC_INVALID_ACTIVATION_CODE, "Invalid activation code provided.", null)
            }
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun validateActivationCode(call: MethodCall, result: Result) {
        try {
            val activationCodeString: String = call.getRequiredArgument(ACTIVATION_CODE)

            result.success(ActivationCodeUtil.validateActivationCode(activationCodeString))
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun validateTypedCharacter(call: MethodCall, result: Result) {
        try {
            val characterInt: Int = call.getRequiredArgument(CHARACTER)
            result.success(ActivationCodeUtil.validateTypedCharacter(characterInt))
        } catch (e: NumberFormatException) {
            Errors.error(result, WrapperException(Errors.EC_WRONG_PARAMETER, "Invalid character format, expected Int", e))
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun correctTypedCharacter(call: MethodCall, result: Result) {
        try {
            val characterInt: Int = call.getRequiredArgument(CHARACTER)
            val corrected: Int = ActivationCodeUtil.validateAndCorrectTypedCharacter(characterInt)

            if (corrected == 0) {
                result.error(Errors.EC_INVALID_CHARACTER, "Invalid character that cannot be corrected.", null)
            } else {
                result.success(corrected)
            }
        } catch (e: NumberFormatException) {
            Errors.error(result, WrapperException(Errors.EC_WRONG_PARAMETER, "Invalid character format, expected Int", e))
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun activationStatusToMap(status: ActivationStatus): Map<String, Any?> {
        return mapOf(
            "state" to activationStateToString(status.state),
            "failCount" to status.failCount,
            "maxFailCount" to status.maxFailCount,
            "remainingAttempts" to status.remainingAttempts,
            "customObject" to status.customObject
        )
    }

    private fun activationStateToString(state: Int): String {
        return when (state) {
            ActivationStatus.State_Created -> "created"
            ActivationStatus.State_Pending_Commit -> "pendingCommit"
            ActivationStatus.State_Active -> "active"
            ActivationStatus.State_Blocked -> "blocked"
            ActivationStatus.State_Removed -> "removed"
            ActivationStatus.State_Deadlock -> "deadlock"
            else -> "unknown"
        }
    }

    private fun buildActivationObject(map: Map<String, Any>): PowerAuthActivation {
        val activationCode = map[ACTIVATION_CODE] as? String
        val identityAttributes = map[IDENTITY_ATTRIBUTES] as? Map<String, String>
        val name = map[ACTIVATION_NAME] as? String

        val activationBuilder = when {
            activationCode != null -> PowerAuthActivation.Builder.activation(activationCode, name)
            identityAttributes != null -> PowerAuthActivation.Builder.customActivation(identityAttributes, name)
            else -> throw WrapperException(Errors.EC_INVALID_ACTIVATION_OBJECT, "Missing activationCode or identityAttributes")
        }

        (map[EXTRAS] as? String)?.let { activationBuilder.setExtras(it) }
        (map[ADDITIONAL_ACTIVATION_OTP] as? String)?.let { activationBuilder.setAdditionalActivationOtp(it) }
        (map[CUSTOM_ATTRIBUTES] as? Map<String, Any>)?.let { activationBuilder.setCustomAttributes(it) }

        return activationBuilder.build()
    }

    private fun buildAuthenticationObject(call: MethodCall, persist: Boolean): PowerAuthAuthentication {
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
            if (password != null) {
                // This iS a copy-paste from RN to keep feature parity, it's also not supported in the Flutter wrapper currentl.
                if (useBiometry) {
                    val biometryKeyIdFromAuthMap = authMap[BIOMETRY_KEY_ID] as? String

                    if (biometryKeyIdFromAuthMap != null) {
                        val biometricKeyBytes = objectRegister.useObject(biometryKeyIdFromAuthMap, ByteArray::class.java)

                        if (biometricKeyBytes != null) {
                            PowerAuthAuthentication.persistWithPasswordAndBiometry(password, biometricKeyBytes)
                        } else {
                            throw WrapperException(
                                Errors.EC_INVALID_NATIVE_OBJECT,
                                "Biometric key for ID '$biometryKeyIdFromAuthMap' not found or expired. It is required for persisting with biometry."
                            )
                        }
                    } else {
                        throw WrapperException(
                            Errors.EC_WRONG_PARAMETER,
                            "'biometryKeyId' is missing in authentication arguments, but is required for persisting with biometry."
                        )
                    }
                } else {
                    PowerAuthAuthentication.persistWithPassword(password)
                }
            } else {
                throw WrapperException(Errors.EC_WRONG_PARAMETER, "Password is required for persisting activation")
            }
        } else {
            if (biometryKeyId != null) {
                val retrievedKey = objectRegister.useObject(biometryKeyId, ByteArray::class.java)

                if (retrievedKey != null) {
                    PowerAuthAuthentication.possessionWithBiometry(retrievedKey)
                } else {
                    throw WrapperException(Errors.EC_INVALID_NATIVE_OBJECT, "Biometric key ID '$biometryKeyId' is no longer valid or expired.")
                }
            } else if (useBiometry) {
                PowerAuthAuthentication.possession()
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

        throw WrapperException(Errors.EC_WRONG_PARAMETER, "Invalid password argument. Expected a map with 'objectId' string.")
    }

    private fun createActivationResultToMap(activationResult: CreateActivationResult): Map<String, Any?> {
        return mapOf(
            "activationFingerprint" to activationResult.activationFingerprint,
            "customAttributes" to activationResult.customActivationAttributes
        )
    }

    private fun authorizationHeaderToMap(header: PowerAuthAuthorizationHttpHeader): Map<String, String> {
        if (header.powerAuthErrorCode != PowerAuthErrorCodes.SUCCEED) {
            throw PowerAuthErrorException(header.powerAuthErrorCode)
        }

        return mapOf(
            "key" to header.key,
            "value" to header.value
        )
    }

    @Throws(WrapperException::class)
    private fun <T> MethodCall.getRequiredArgument(key: String): T {
        return this.argument<T>(key) ?: throw WrapperException(
            Errors.EC_WRONG_PARAMETER,
            "Missing required argument: '$key'"
        )
    }

    private fun extractPromptStrings(promptMap: Map<String, Any>?): Pair<String, String> {
        val title = promptMap?.get(PROMPT_TITLE) as? String ?: Constants.MISSING_REQUIRED_STRING
        val description = promptMap?.get(PROMPT_MESSAGE) as? String ?: Constants.MISSING_REQUIRED_STRING
        return Pair(title, description)
    }

    @Throws(WrapperException::class)
    private fun validateBiometryBeforeUse(sdk: PowerAuthSDK) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            when (val status = BiometricAuthentication.canAuthenticate(context)) {
                BiometricStatus.OK -> {
                    if (sdk.hasValidActivation() && !sdk.hasBiometryFactor(context)) {
                        throw WrapperException(Errors.EC_BIOMETRY_NOT_CONFIGURED, "Biometry factor is not configured for this activation.")
                    }
                }
                BiometricStatus.NOT_AVAILABLE -> throw WrapperException(Errors.EC_BIOMETRY_NOT_AVAILABLE, "Biometry is not available on this device currently.")
                BiometricStatus.NOT_ENROLLED -> throw WrapperException(Errors.EC_BIOMETRY_NOT_ENROLLED, "No biometry enrolled on the device.")
                BiometricStatus.NOT_SUPPORTED -> throw WrapperException(Errors.EC_BIOMETRY_NOT_SUPPORTED, "Biometry is not supported on this device.")
                else -> throw WrapperException(Errors.EC_BIOMETRY_NOT_AVAILABLE, "Biometry check failed with status: $status")
            }
        } else {
            throw WrapperException(Errors.EC_BIOMETRY_NOT_SUPPORTED, "Biometry requires Android 6.0 (API 23) or higher")
        }
    }

    private fun removeNativeObject(call: MethodCall, result: Result) {
        try {
            val objectId: String = call.getRequiredArgument(OBJECT_ID)
            val removed = objectRegister.removeObject(objectId)
            result.success(removed)
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun buildPowerAuthConfiguration(instanceId: String, map: Map<String, Any>): PowerAuthConfiguration {
        val baseEndpointUrl = map[BASE_ENDPOINT_URL] as? String
            ?: throw WrapperException(Errors.EC_WRONG_PARAMETER, "Missing '${BASE_ENDPOINT_URL}' in configuration map")
        val configurationString = map[CONFIGURATION_STRING] as? String
            ?: throw WrapperException(Errors.EC_WRONG_PARAMETER, "Missing '${CONFIGURATION_STRING}' string in configuration map")

        return PowerAuthConfiguration.Builder(instanceId, baseEndpointUrl, configurationString).build()
    }

    private fun buildPowerAuthKeychainConfiguration(
        keychainMap: Map<String, Any>?,
        biometryMap: Map<String, Any>?
    ): PowerAuthKeychainConfiguration {
        val builder = PowerAuthKeychainConfiguration.Builder()

        biometryMap?.let {
            (it[LINK_ITEMS_TO_CURRENT_SET] as? Boolean)?.let { v -> builder.linkBiometricItemsToCurrentSet(v) }
            (it[CONFIRM_BIOMETRIC_AUTHENTICATION] as? Boolean)?.let { v -> builder.confirmBiometricAuthentication(v) }
            (it[AUTHENTICATE_ON_BIOMETRIC_KEY_SETUP] as? Boolean)?.let { v -> builder.authenticateOnBiometricKeySetup(v) }
            (it[FALLBACK_TO_SHARED_BIOMETRY_KEY] as? Boolean)?.let { v -> builder.enableFallbackToSharedBiometryKey(v) }
        }

        keychainMap?.let {
            (it[MINIMAL_REQUIRED_KEYCHAIN_PROTECTION] as? String)?.let { v ->
                builder.minimalRequiredKeychainProtection(getKeychainProtectionFromString(v))
            }
        }

        return builder.build()
    }

    @KeychainProtection
    private fun getKeychainProtectionFromString(stringValue: String?): Int {
        return when (stringValue) {
            "none" -> KeychainProtection.NONE
            "software" -> KeychainProtection.SOFTWARE
            "hardware" -> KeychainProtection.HARDWARE
            "strongbox" -> KeychainProtection.STRONGBOX
            else -> KeychainProtection.NONE
        }
    }

    @Throws(PowerAuthErrorException::class)
    private fun getPowerAuthInstance(instanceId: String): PowerAuthSDK? {
        if (!objectRegister.isValidObjectId(instanceId)) {
            throw PowerAuthErrorException(PowerAuthErrorCodes.WRONG_PARAMETER, "Instance ID is missing or invalid.")
        }

        return objectRegister.findObject(instanceId, PowerAuthSDK::class.java)
    }

    @Throws(Throwable::class)
    private fun registerPowerAuthInstance(
        instanceId: String,
        factory: PowerAuthObjectRegister.ObjectFactory<PowerAuthSDK>
    ): Boolean {
        if (!objectRegister.isValidObjectId(instanceId)) {
            throw PowerAuthErrorException(PowerAuthErrorCodes.WRONG_PARAMETER, "Instance ID is missing or invalid for registration.")
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
            throw PowerAuthErrorException(PowerAuthErrorCodes.WRONG_PARAMETER, "Instance ID is missing or invalid for unregistration.")
        }

        objectRegister.removeAllObjectsWithTag(instanceId)
    }

    private fun <R> withPassword(call: MethodCall, result: Result, block: (password: Password) -> R) {
        try {
            val objectId: String = call.getRequiredArgument(OBJECT_ID)
            val password = objectRegister.touchObject(objectId, Password::class.java)
                ?: throw WrapperException(Errors.EC_INVALID_NATIVE_OBJECT, "Password object '$objectId' is no longer valid or not found.")

            val blockResult = block(password)

            // TODO: double-check whether we should always result strongly or whether to move this into the block
            if (blockResult is Unit) {
                result.success(null)
            } else {
                result.success(blockResult)
            }
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun <R> withPasswordAndCharacter(call: MethodCall, result: Result, block: (password: Password, codePoint: Int) -> R) {
        try {
            val objectId: String = call.getRequiredArgument(OBJECT_ID)
            val characterInt: Int = call.getRequiredArgument(CHARACTER)

            if (characterInt < 0 || characterInt > Constants.CODEPOINT_MAX) {
                throw WrapperException(Errors.EC_WRONG_PARAMETER, "Invalid CodePoint: $characterInt")
            }

            val password = objectRegister.touchObject(objectId, Password::class.java)
                ?: throw WrapperException(Errors.EC_INVALID_NATIVE_OBJECT, "Password object '$objectId' is no longer valid or not found.")

            val blockResult = block(password, characterInt)

            // TODO: double-check whether we should always result strongly or whether to move this into the block
            if (blockResult is Unit) {
                result.success(null)
            } else {
                result.success(blockResult)
            }
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun passwordInitialize(call: MethodCall, result: Result) {
        try {
            val destroyOnUse: Boolean = call.argument<Boolean>(PASSWORD_DESTROY_ON_USE) ?: false
            val ownerId: String? = call.argument<String>(PASSWORD_OWNER_ID)
            val autoreleaseTimeMs: Int = call.argument<Int>(PASSWORD_AUTORELEASE_TIME) ?: Constants.PASSWORD_KEY_KEEP_ALIVE_TIME

            if (ownerId != null && objectRegister.findObject(ownerId, PowerAuthSDK::class.java) == null) {
                throw WrapperException(Errors.EC_INSTANCE_NOT_CONFIGURED, "PowerAuth instance for ownerId '$ownerId' is not configured.")
            }

            var actualReleaseTime = Constants.PASSWORD_KEY_KEEP_ALIVE_TIME

            if (autoreleaseTimeMs > 0) {
                actualReleaseTime = autoreleaseTimeMs
            }

            val passwordInstance = ManagedAny.wrap(Password()) { obj: Password -> obj.destroy() }

            val releasePolicies = mutableListOf<ReleasePolicy>()
            if (destroyOnUse) {
                releasePolicies.add(ReleasePolicy.afterUse(1))
            }
            releasePolicies.add(ReleasePolicy.keepAlive(actualReleaseTime))

            val objectId = objectRegister.registerObject(passwordInstance, ownerId, releasePolicies)
            result.success(objectId)
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun passwordClear(call: MethodCall, result: Result) {
        withPassword(call, result) { password ->
            return@withPassword password.clear()
        }
    }

    private fun passwordLength(call: MethodCall, result: Result) {
        withPassword(call, result) { password ->
            return@withPassword password.length()
        }
    }

    private fun passwordIsEqual(call: MethodCall, result: Result) {
        try {
            val id1: String = call.getRequiredArgument(PASSWORD_ID1)
            val id2: String = call.getRequiredArgument(PASSWORD_ID2)

            val p1 = objectRegister.touchObject(id1, Password::class.java)
                ?: throw WrapperException(Errors.EC_INVALID_NATIVE_OBJECT, "Password object '$id1' is no longer valid or not found.")
            val p2 = objectRegister.touchObject(id2, Password::class.java)
                ?: throw WrapperException(Errors.EC_INVALID_NATIVE_OBJECT, "Password object '$id2' is no longer valid or not found.")

            result.success(p1.isEqualToPassword(p2))
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun passwordAddCharacter(call: MethodCall, result: Result) {
        withPasswordAndCharacter(call, result) { password, codePoint ->
            password.addCharacter(codePoint)

            return@withPasswordAndCharacter password.length()
        }
    }

    private fun passwordInsertCharacter(call: MethodCall, result: Result) {
        try {
            val position: Int = call.getRequiredArgument(PASSWORD_POSITION)

            withPasswordAndCharacter(call, result) { password, codePoint ->
                if (position >= 0 && position <= password.length()) {
                    password.insertCharacter(codePoint, position)

                    return@withPasswordAndCharacter password.length()
                } else {
                    throw WrapperException(Errors.EC_WRONG_PARAMETER, "Position $position is out of range for password length ${password.length()}.")
                }
            }
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun passwordRemoveCharacterAt(call: MethodCall, result: Result) {
        try {
            val position: Int = call.getRequiredArgument(PASSWORD_POSITION)

            withPassword(call, result) { password ->
                if (position >= 0 && position < password.length()) {
                    password.removeCharacter(position)

                    return@withPassword password.length()
                } else {
                    if (password.length() == 0 && position == 0) {
                        return@withPassword 0
                    } else {
                        throw WrapperException(Errors.EC_WRONG_PARAMETER, "Position $position is out of range for password length ${password.length()}.")
                    }
                }
            }
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun passwordRemoveLastCharacter(call: MethodCall, result: Result) {
        withPassword(call, result) { password ->
            if (password.length() > 0) {
                password.removeLastCharacter()
            }

            return@withPassword password.length()
        }
    }
}
