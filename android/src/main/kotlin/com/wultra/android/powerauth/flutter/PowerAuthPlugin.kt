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

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class PowerAuthPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel : MethodChannel

  private lateinit var passwordPlugin: PowerAuthPasswordPlugin

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
      channel = MethodChannel(flutterPluginBinding.binaryMessenger, "powerauth_plugin")
      channel.setMethodCallHandler(this)

      // Note that this is a real Flutter way how to register sub-plugin so that they all benefit from the "autolinking" of the main one...
      // But lets test this a lot:))
      passwordPlugin = PowerAuthPasswordPlugin()
      passwordPlugin.onAttachedToEngine(flutterPluginBinding)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {

    val instanceId = instanceManager.getOptionalArgument<String>(ArgKey.instanceId, call) ?: ""

    when (call.method) {
        // "configure" -> configure(call, result)
        // "isConfigured" -> isConfigured(instanceId, result)
        // "deconfigure" -> deconfigure(instanceId, result)
        // "hasValidActivation" -> hasValidActivation(instanceId, result)
        // "canStartActivation" -> canStartActivation(instanceId, result)
        // "hasPendingActivation" -> hasPendingActivation(instanceId, result)
        // "getActivationIdentifier" -> getActivationIdentifier(instanceId, result)
        // "getActivationFingerprint" -> getActivationFingerprint(instanceId, result)
        // "fetchActivationStatus" -> fetchActivationStatus(instanceId, result)
        // "removeActivationLocal" -> removeActivationLocal(instanceId, result)
        // "removeActivationWithAuthentication" -> removeActivationWithAuthentication(call, instanceId, result)
        // "getExternalPendingOperation" -> getExternalPendingOperation(instanceId, result)
        // "createActivation" -> createActivation(call, instanceId, result)
        // "persistActivation" -> persistActivation(call, instanceId, result)
        // "validatePassword" -> validatePassword(call, instanceId, result)
        // "changePassword" -> changePassword(call, instanceId, result)
        // "unsafeChangePassword" -> unsafeChangePassword(call, instanceId, result)
        // "requestGetSignature" -> requestGetSignature(call, instanceId, result)
        // "requestSignature" -> requestSignature(call, instanceId, result)
        // "offlineSignature" -> offlineSignature(call, instanceId, result)
        // "verifyServerSignedData" -> verifyServerSignedData(call, instanceId, result)
        "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
        else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
      channel.setMethodCallHandler(null)

      passwordPlugin.onDetachedFromEngine(binding)
  }
}
