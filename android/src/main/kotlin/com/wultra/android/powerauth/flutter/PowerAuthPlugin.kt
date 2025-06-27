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

import com.wultra.android.powerauth.flutter.internal.core.PowerAuthServiceRegistry
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * PowerAuthPlugin integrates the PowerAuth SDK with Flutter, enabling secure authentication and authorization
 * features in Flutter apps by bridging native Android functionality to Dart code via method channels.
 */
class PowerAuthPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private lateinit var serviceRegistry: PowerAuthServiceRegistry

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "powerauth_plugin")
        channel.setMethodCallHandler(this)

        // Initialize the service registry (or get the existing one)
        serviceRegistry = PowerAuthServiceRegistry.getInstance(flutterPluginBinding.applicationContext)
        // Tell the registry that the plugin is attached to keep track of the plugin lifecycle
        PowerAuthServiceRegistry.onPluginAttached()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        // Tell the registry that the plugin is detached so it can clean up resources
        PowerAuthServiceRegistry.onPluginDetached()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        serviceRegistry.addActivity(binding.activity)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        // Activity will be removed automatically when deallocated
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        serviceRegistry.addActivity(binding.activity)
    }

    override fun onDetachedFromActivity() {
        // Activity will be removed automatically when deallocated
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
                service.handlers[methodName]?.invoke(call, result)
                    ?: result.notImplemented()
            } ?: result.notImplemented()
        } catch (e: Exception) {
            Errors.error(result, e)
        }
    }
}
