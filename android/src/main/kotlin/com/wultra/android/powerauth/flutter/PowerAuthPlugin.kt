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

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.getlime.security.powerauth.core.*
import io.getlime.security.powerauth.exception.*
import io.getlime.security.powerauth.networking.response.*
import io.getlime.security.powerauth.sdk.*
import io.getlime.security.powerauth.core.Password
import io.getlime.security.powerauth.exception.PowerAuthErrorException
import io.getlime.security.powerauth.exception.PowerAuthErrorCodes

// TODO: migrate method docs from RN
class PowerAuthPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel : MethodChannel
    private lateinit var context: Context

    private val instances = mutableMapOf<String, PowerAuthSDK>()

    companion object ArgKeys {
        const val INSTANCE_ID = "instanceId"
        const val CONFIGURATION = "configuration"
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
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "powerauth_plugin")
        channel.setMethodCallHandler(this)

        // TODO: implement back sub-module registration when we need it
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
            "configure" -> configure(call, result)
            "isConfigured" -> isConfigured(call, result)
            "deconfigure" -> deconfigure(call, result)
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
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)

        // TODO(post-beta): Flutter can destroy / recreate the plugin object if the engine detaches.
        // This can happen f.e. with the back button press on the first screen (app keeps running, but plugins re-attach.
        // We should explore this more (and cache the state?).
        instances.clear()
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

    // TODO: copy-pasted placeholder for when we have biometry
    private fun usePowerAuthOnMainThread(call: MethodCall, result: Result, block: (sdk: PowerAuthSDK) -> Unit) {
//        Handler(Looper.getMainLooper()).post {
//            usePowerAuth(call, result, block)
//        }
    }

    private fun configure(call: MethodCall, result: Result) {
        try {
            val instanceId: String = call.getRequiredArgument(INSTANCE_ID)
            val configurationMap: Map<String, Any> = call.getRequiredArgument(CONFIGURATION)
            if (instances.containsKey(instanceId)) {
                throw WrapperException(Errors.EC_WRONG_PARAMETER, "PowerAuth instance '$instanceId' is already configured.")
            }

            val powerAuthConfiguration = buildPowerAuthConfiguration(instanceId, configurationMap)

            val sdk = PowerAuthSDK.Builder(powerAuthConfiguration).build(context)

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
            val dataBytes = DataFormat.BASE64.decodeBytes(dataString)
            val signatureBytes = DataFormat.BASE64.decodeBytes(signature)

            val isValid = sdk.verifyServerSignedData(dataBytes, signatureBytes, useMasterKey)

            result.success(isValid)
        }
    }

    private fun buildPowerAuthConfiguration(instanceId: String, map: Map<String, Any>): PowerAuthConfiguration {
        val baseEndpointUrl = map["baseEndpointUrl"] as? String ?: throw WrapperException(Errors.EC_WRONG_PARAMETER, "Missing 'baseEndpointUrl' in configuration")
        val configuration = map["configuration"] as? String ?: throw WrapperException(Errors.EC_WRONG_PARAMETER, "Missing 'configuration' in configuration")

        return PowerAuthConfiguration.Builder(instanceId, baseEndpointUrl, configuration).build()
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
        val activationCode = map["activationCode"] as? String
        val identityAttributes = map["identityAttributes"] as? Map<String, String>
        val name = map["activationName"] as? String

        val activationBuilder = when {
            activationCode != null -> PowerAuthActivation.Builder.activation(activationCode, name)
            identityAttributes != null -> PowerAuthActivation.Builder.customActivation(identityAttributes, name)
            else -> throw WrapperException(Errors.EC_INVALID_ACTIVATION_OBJECT, "Missing activationCode or identityAttributes")
        }

        (map["extras"] as? String)?.let { activationBuilder.setExtras(it) }
        (map["additionalActivationOtp"] as? String)?.let { activationBuilder.setAdditionalActivationOtp(it) }
        (map["customAttributes"] as? Map<String, Any>)?.let { activationBuilder.setCustomAttributes(it) }

        return activationBuilder.build()
    }

    private fun buildAuthenticationObject(call: MethodCall, persist: Boolean): PowerAuthAuthentication {
        val authMap: Map<String, Any> = call.getRequiredArgument(AUTHENTICATION)

//        val useBiometry = authMap["isBiometry"] as? Boolean ?: false
        val passwordMap = authMap["password"] as? Map<String, Any>

        val password: Password? = if (passwordMap != null) {
            buildPasswordObject(passwordMap)
        } else {
            null
        }

        return when {
            persist && password != null -> {
                PowerAuthAuthentication.persistWithPassword(password)
            }
            persist -> throw WrapperException(Errors.EC_WRONG_PARAMETER, "Password is required for persisting activation")

//            useBiometry -> {
//                 PowerAuthAuthentication.possessionWithBiometry()
//             }
            password != null -> PowerAuthAuthentication.possessionWithPassword(password)
            else -> PowerAuthAuthentication.possession()
        }
    }

    private fun buildPasswordObject(map: Map<String, Any>): Password {
        // TODO: move from Strings when we have ObjectRegister
        val passwordString = map["password"] as? String ?: throw WrapperException(Errors.EC_WRONG_PARAMETER, "Missing 'password' string in password object")
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
}
