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
import java.util.UUID
import kotlin.collections.set

import android.util.Pair
import androidx.core.util.component1
import androidx.core.util.component2

// TODO: migrate method docs from RN
class PowerAuthPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel : MethodChannel
    private lateinit var context: Context

    private val instances = mutableMapOf<String, PowerAuthSDK>()
    private var currentActivity: Activity? = null
    private val biometricKeyCache = mutableMapOf<String, Pair<ByteArray, Long>>()

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
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "powerauth_plugin")
        channel.setMethodCallHandler(this)

        // TODO: implement back sub-module registration when we need it
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)

        // TODO(post-beta): Flutter can destroy / recreate the plugin object if the engine detaches.
        // This can happen f.e. with the back button press on the first screen (app keeps running, but plugins re-attach.
        // We should explore this more (and cache the state?).
        instances.clear()
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
            "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
            "configure" -> configure(call, result)
            "isConfigured" -> isConfigured(call, result)
            "deconfigure" -> deconfigure(call, result)
            "util_parseActivationCode" -> parseActivationCode(call, result)
            "util_validateActivationCode" -> validateActivationCode(call, result)
            "util_validateTypedCharacter" -> validateTypedCharacter(call, result)
            "util_correctTypedCharacter" -> correctTypedCharacter(call, result)
            "hasValidActivation" -> hasValidActivation(call, result)
            "canStartActivation" -> canStartActivation(call, result)
            "hasPendingActivation" -> hasPendingActivation(call, result)
            "getActivationIdentifier" -> getActivationIdentifier(call, result)
            "getActivationFingerprint" -> getActivationFingerprint(call, result)
            "fetchActivationStatus" -> fetchActivationStatus(call, result)
            "removeActivationLocal" -> removeActivationLocal(call, result)
            "removeActivationWithAuthentication" -> removeActivationWithAuthentication(call, result)
            "createActivation" -> createActivation(call, result)
            "persistActivation" -> persistActivation(call, result)
            "validatePassword" -> validatePassword(call, result)
            "changePassword" -> changePassword(call, result)
            "requestGetSignature" -> requestGetSignature(call, result)
            "requestSignature" -> requestSignature(call, result)
            "offlineSignature" -> offlineSignature(call, result)
            "verifyServerSignedData" -> verifyServerSignedData(call, result)
            "getBiometryInfo" -> getBiometryInfo(result)
            "addBiometryFactor" -> addBiometryFactor(call, result)
            "hasBiometryFactor" -> hasBiometryFactor(call, result)
            "removeBiometryFactor" -> removeBiometryFactor(call, result)
            "authenticateWithBiometry" -> authenticateWithBiometry(call, result)
            else -> result.notImplemented()
        }
    }

    private fun usePowerAuth(call: MethodCall, result: Result, block: (sdk: PowerAuthSDK) -> Unit) {
        try {
            val instanceId: String = call.getRequiredArgument(INSTANCE_ID)
            val sdk = instances[instanceId] ?: throw WrapperException(Errors.EC_INSTANCE_NOT_CONFIGURED, "PowerAuth instance '$instanceId' not configured.")

            block(sdk)
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun usePowerAuthOnMainThread(call: MethodCall, result: Result, block: (sdk: PowerAuthSDK) -> Unit) {
        Handler(Looper.getMainLooper()).post {
            usePowerAuth(call, result, block)
        }
    }

    private fun configure(call: MethodCall, result: Result) {
        try {
            val instanceId: String = call.getRequiredArgument(INSTANCE_ID)
            val configurationMap: Map<String, Any> = call.getRequiredArgument(CONFIGURATION)
            val biometryConfigMap = call.argument<Map<String, Any>>(BIOMETRY_CONFIGURATION)
            val keychainConfigMap = call.argument<Map<String, Any>>(KEYCHAIN_CONFIGURATION)

            if (instances.containsKey(instanceId)) {
                throw WrapperException(Errors.EC_WRONG_PARAMETER, "PowerAuth instance '$instanceId' is already configured.")
            }
            val powerAuthConfiguration = buildPowerAuthConfiguration(instanceId, configurationMap)
            val keychainConfiguration = buildPowerAuthKeychainConfiguration(keychainConfigMap, biometryConfigMap)

            val sdk = PowerAuthSDK.Builder(powerAuthConfiguration)
                .keychainConfiguration(keychainConfiguration)
                .build(context)

            instances[instanceId] = sdk
            result.success(null)
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun isConfigured(call: MethodCall, result: Result) {
        try {
            val instanceId: String = call.getRequiredArgument(INSTANCE_ID)
            result.success(instances.containsKey(instanceId))
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun deconfigure(call: MethodCall, result: Result) {
        try {
            val instanceId: String = call.getRequiredArgument(INSTANCE_ID)
            instances.remove(instanceId)

            // TODO: check if SDK needs explicit cleanup
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
            val password = buildPasswordObject(passwordMap)

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

            val oldPassword = buildPasswordObject(oldPasswordMap)
            val newPassword = buildPasswordObject(newPasswordMap)

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
            val signatureBytes = signature.toByteArray()

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
            val corePassword = buildPasswordObject(passwordMap)

            try {
                // validateBiometryBeforeUse(sdk)

                val activity = currentActivity
                if (activity == null) {
                    throw WrapperException(Errors.EC_FLUTTER_ERROR, "Android Activity is not available when attempting to add biometry factor.")
                }
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

            try {
                validateBiometryBeforeUse(sdk)

                val activity = currentActivity
                if (activity == null) {
                    throw WrapperException(Errors.EC_FLUTTER_ERROR, "Android Activity is not available when attempting biometric authentication.")
                }
                if (activity !is FragmentActivity) {
                    throw WrapperException(Errors.EC_FLUTTER_ERROR, "Attached Android Activity is not a FragmentActivity, which is required for biometry.")
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
                                Errors.error(result, WrapperException(Errors.EC_FLUTTER_ERROR, "Biometric key was missing after successful authentication."))
                                return
                            }

                            val keyId = UUID.randomUUID().toString()
                            val timestamp = System.currentTimeMillis()

                            biometricKeyCache[keyId] = Pair(key, timestamp)
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
            ActivationStatus.State_Pending_Commit -> "pending_commit"
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
            buildPasswordObject(passwordMap)
        } else {
            null
        }

        cleanupExpiredBiometricKeys()

        return if (persist) {
            if (password != null) {
                PowerAuthAuthentication.persistWithPassword(password)
            } else {
                throw WrapperException(Errors.EC_WRONG_PARAMETER, "Password is required for persisting activation")
            }
        } else {
            if (biometryKeyId != null) {
                val keyEntry = biometricKeyCache.remove(biometryKeyId)

                if (keyEntry != null) {
                    PowerAuthAuthentication.possessionWithBiometry(keyEntry.first)
                } else {
                    throw WrapperException(Errors.EC_INVALID_NATIVE_OBJECT, "Biometric key ID is no longer valid or expired.")
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

    private fun buildPasswordObject(map: Map<String, Any>): Password {
        // TODO: move from Strings when we have ObjectRegister
        val passwordString = map[PASSWORD] as? String ?: throw WrapperException(Errors.EC_WRONG_PARAMETER, "Missing 'password' string in password object")
        return Password(passwordString)
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

    private fun cleanupExpiredBiometricKeys() {
        val now = System.currentTimeMillis()
        val iterator = biometricKeyCache.entries.iterator()

        while (iterator.hasNext()) {
            val entry = iterator.next()
            if (now - entry.value.second >= Constants.BIOMETRY_KEY_KEEP_ALIVE_TIME) {
                iterator.remove()
            }
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
}
