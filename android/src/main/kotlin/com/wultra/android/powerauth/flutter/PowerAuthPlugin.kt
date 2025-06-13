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
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import com.wultra.android.powerauth.flutter.internal.core.PowerAuthServiceRegistry
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthEncryptorService
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthLoggingService
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthPasswordService
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthRegisterService
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthService
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthUtilsService
import io.flutter.BuildConfig

// TODO: migrate method docs from RN
class PowerAuthPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    private var currentActivity: Activity? = null

    private lateinit var objectRegister: PowerAuthObjectRegister
    private lateinit var serviceRegistry: PowerAuthServiceRegistry

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "powerauth_plugin")
        channel.setMethodCallHandler(this)

        objectRegister = PowerAuthObjectRegister(BuildConfig.DEBUG)
        serviceRegistry = PowerAuthServiceRegistry

        serviceRegistry.registerAll(
            PowerAuthService(objectRegister, context, getCurrentActivity = { currentActivity }),
            PowerAuthPasswordService(objectRegister),
            PowerAuthUtilsService(),
            PowerAuthEncryptorService(objectRegister, context),
            PowerAuthRegisterService(objectRegister),
            PowerAuthLoggingService()
        )
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
        try {
            val methodServicePair = call.method.split("_")

            // TODO: discuss renaming the base plugin methods to powerauth_*?
            val (serviceName, methodName) = if (methodServicePair.size == 1) {
                "powerauth" to methodServicePair[0]
            } else {
                methodServicePair.getOrNull(0) to methodServicePair.getOrNull(1)
            }

            if (serviceName == null || methodName == null) {
                result.notImplemented()
                return
            }

            serviceRegistry[serviceName]?.let { service ->
                service.handlers[methodName]?.handle(call, result)
                    ?: result.notImplemented()
            } ?: result.notImplemented()
        } catch (e: Exception) {
            Errors.error(result, e)
        }
    }
}
