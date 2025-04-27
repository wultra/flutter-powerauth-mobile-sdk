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
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.getlime.security.powerauth.core.*
import io.getlime.security.powerauth.exception.*
import io.getlime.security.powerauth.networking.response.*
import io.getlime.security.powerauth.sdk.*

class PowerAuthPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel : MethodChannel
    private lateinit var context: Context

    private val instances = mutableMapOf<String, PowerAuthSDK>()
    private val mainThreadHandler = Handler(Looper.getMainLooper())

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
            val instanceId: String = call.argument("instanceId") ?: throw WrapperException(Errors.EC_WRONG_PARAMETER, "Missing instanceId parameter")
            val sdk = instances[instanceId] ?: throw WrapperException(Errors.EC_INSTANCE_NOT_CONFIGURED, "PowerAuth instance '$instanceId' not configured.")

            block(sdk)
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    // TODO: copy-pasted placeholder for when we have biometry
    private fun usePowerAuthOnMainThread(call: MethodCall, result: Result, block: (sdk: PowerAuthSDK) -> Unit) {
        mainThreadHandler.post {
            usePowerAuth(call, result, block)
        }
    }

    private fun postResultSuccess(result: Result, data: Any?) {
        mainThreadHandler.post { result.success(data) }
    }

    private fun postResultError(result: Result, throwable: Throwable) {
        mainThreadHandler.post { Errors.error(result, throwable) }
    }

    private fun configure(call: MethodCall, result: Result) {
        try {
            val instanceId: String = call.argument("instanceId") ?: throw WrapperException(Errors.EC_WRONG_PARAMETER, "Missing instanceId parameter")
            val configurationMap: Map<String, Any> = call.argument("configuration") ?: throw WrapperException(Errors.EC_WRONG_PARAMETER, "Missing configuration parameter")
            if (instances.containsKey(instanceId)) {
                throw WrapperException(Errors.EC_WRONG_PARAMETER, "PowerAuth instance '$instanceId' is already configured.")
            }

            val powerAuthConfiguration = buildPowerAuthConfiguration(instanceId, configurationMap)
            val clientConfiguration = buildPowerAuthClientConfiguration(configurationMap["clientConfiguration"] as? Map<String, Any> ?: emptyMap())

            val sdk = PowerAuthSDK.Builder(powerAuthConfiguration)
                .clientConfiguration(clientConfiguration)
                .build(context)

            instances[instanceId] = sdk
            result.success(null)
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun isConfigured(call: MethodCall, result: Result) {
        try {
            val instanceId: String = call.argument("instanceId") ?: throw WrapperException(Errors.EC_WRONG_PARAMETER, "Missing instanceId parameter")
            result.success(instances.containsKey(instanceId))
        } catch (t: Throwable) {
            Errors.error(result, t)
        }
    }

    private fun deconfigure(call: MethodCall, result: Result) {
        try {
            val instanceId: String = call.argument("instanceId") ?: throw WrapperException(Errors.EC_WRONG_PARAMETER, "Missing instanceId parameter")
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
                    postResultSuccess(result, activationStatusToMap(status))
                }
                override fun onActivationStatusFailed(t: Throwable) {
                    postResultError(result, t)
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
            val authentication = buildAuthenticationObject(call, "authentication", result, persist = false)

            sdk.removeActivationWithAuthentication(context, authentication, object: IActivationRemoveListener {
                override fun onActivationRemoveSucceed() {
                    postResultSuccess(result, null)
                }
                override fun onActivationRemoveFailed(t: Throwable) {
                    postResultError(result, t)
                }
            })
        }
    }

    private fun createActivation(call: MethodCall, result: Result) {
        usePowerAuth(call, result) { sdk ->
            val activationMap: Map<String, Any> = call.argument("activation") ?: throw WrapperException(Errors.EC_WRONG_PARAMETER, "Missing activation parameter")
            val activation = buildActivationObject(activationMap)

            sdk.createActivation(activation, object: ICreateActivationListener {
                override fun onActivationCreateSucceed(activationResult: CreateActivationResult) {
                    postResultSuccess(result, createActivationResultToMap(activationResult))
                }
                override fun onActivationCreateFailed(t: Throwable) {
                    postResultError(result, t)
                }
            })
        }
    }

    private fun persistActivation(call: MethodCall, result: Result) {
        usePowerAuth(call, result) { sdk ->
            val authentication = buildAuthenticationObject(call, "authentication", result, persist = true)
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
            val passwordMap: Map<String, Any> = call.argument("password") ?: throw WrapperException(Errors.EC_WRONG_PARAMETER, "Missing password parameter")
            val password = buildPasswordObject(passwordMap)

            sdk.validatePassword(context, password, object: IValidatePasswordListener {
                override fun onPasswordValid() {
                    postResultSuccess(result, null)
                }
                override fun onPasswordValidationFailed(t: Throwable) {
                    postResultError(result, t)
                }
            })
        }
    }

    private fun changePassword(call: MethodCall, result: Result) {
        usePowerAuth(call, result) { sdk ->
            val oldPasswordMap: Map<String, Any> = call.argument("oldPassword") ?: throw WrapperException(Errors.EC_WRONG_PARAMETER, "Missing oldPassword parameter")
            val newPasswordMap: Map<String, Any> = call.argument("newPassword") ?: throw WrapperException(Errors.EC_WRONG_PARAMETER, "Missing newPassword parameter")

            val oldPassword = buildPasswordObject(oldPasswordMap)
            val newPassword = buildPasswordObject(newPasswordMap)

            sdk.changePassword(context, oldPassword, newPassword, object: IChangePasswordListener {
                override fun onPasswordChangeSucceed() {
                    postResultSuccess(result, null)
                }
                override fun onPasswordChangeFailed(t: Throwable) {
                    postResultError(result, t)
                }
            })
        }
    }

    private fun requestGetSignature(call: MethodCall, result: Result) {
        usePowerAuth(call, result) { sdk ->
            val authentication = buildAuthenticationObject(call, "authentication", result, persist = false)
            val uriId: String = call.argument("uriId") ?: throw WrapperException(Errors.EC_WRONG_PARAMETER, "Missing uriId parameter")
            val queryParams: Map<String, String>? = call.argument("queryParams")

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
            val authentication = buildAuthenticationObject(call, "authentication", result, persist = false)
            val method: String = call.argument("method") ?: throw WrapperException(Errors.EC_WRONG_PARAMETER, "Missing method parameter")
            val uriId: String = call.argument("uriId") ?: throw WrapperException(Errors.EC_WRONG_PARAMETER, "Missing uriId parameter")
            val bodyString: String? = call.argument("body")
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
            val authentication = buildAuthenticationObject(call, "authentication", result, persist = false)
            val uriId: String = call.argument("uriId") ?: throw WrapperException(Errors.EC_WRONG_PARAMETER, "Missing uriId parameter")
            val nonce: String = call.argument("nonce") ?: throw WrapperException(Errors.EC_WRONG_PARAMETER, "Missing nonce parameter")
            val bodyString: String? = call.argument("body")
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
            val dataString: String = call.argument("data") ?: throw WrapperException(Errors.EC_WRONG_PARAMETER, "Missing data parameter")
            val signature: String = call.argument("signature") ?: throw WrapperException(Errors.EC_WRONG_PARAMETER, "Missing signature parameter")
            val useMasterKey: Boolean = call.argument("useMasterKey") ?: false
            val dataBytes = DataFormat.BASE64.decodeBytes(dataString)
            val signatureBytes = DataFormat.BASE64.decodeBytes(signature)

            val isValid = sdk.verifyServerSignedData(dataBytes, signatureBytes, useMasterKey)

            result.success(isValid)
        }
    }

    private fun buildPowerAuthConfiguration(instanceId: String, map: Map<String, Any>): PowerAuthConfiguration {
        val baseEndpointUrl = map["baseEndpointUrl"] as? String ?: throw WrapperException(Errors.EC_WRONG_PARAMETER, "Missing 'apiUrl' in configuration")
        val configuration = map["configuration"] as? String ?: throw WrapperException(Errors.EC_WRONG_PARAMETER, "Missing 'appKey' in configuration")


        return PowerAuthConfiguration.Builder(instanceId, baseEndpointUrl, configuration).build()
    }

    private fun buildPowerAuthClientConfiguration(map: Map<String, Any>): PowerAuthClientConfiguration {
        val builder = PowerAuthClientConfiguration.Builder()
        // TODO: add full configs when implemented in Dart
        return builder.build()
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

    private fun buildAuthenticationObject(call: MethodCall, argumentName: String, result: Result, persist: Boolean): PowerAuthAuthentication {
        val authMap: Map<String, Any> = call.argument(argumentName) ?: throw WrapperException(Errors.EC_WRONG_PARAMETER, "Missing $argumentName parameter")

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
}
