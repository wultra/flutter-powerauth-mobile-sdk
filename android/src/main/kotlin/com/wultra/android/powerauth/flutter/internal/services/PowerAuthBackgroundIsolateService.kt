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
import android.os.Handler
import android.os.Looper
import androidx.fragment.app.FragmentActivity
import com.wultra.android.powerauth.flutter.internal.core.BasePowerAuthService
import com.wultra.android.powerauth.flutter.internal.utils.PowerAuthLogger
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterShellArgs
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result

internal class PowerAuthBackgroundIsolateService(
    private val context: Context,
    private val getCurrentActivity: () -> FragmentActivity?
) : BasePowerAuthService(null) {

    override val name: String = "isolate"

    private var backgroundFlutterEngine: FlutterEngine? = null

    private object HandlerNames {
        const val START_BACKGROUND_ISOLATE = "startBackgroundIsolate"
        const val REMOVE_BACKGROUND_ISOLATE = "removeBackgroundIsolate"
    }

    override val handlers by lazy {
        mapOf(
            HandlerNames.START_BACKGROUND_ISOLATE to ::startBackgroundIsolate,
            HandlerNames.REMOVE_BACKGROUND_ISOLATE to ::removeBackgroundIsolate
        )
    }

    fun startBackgroundIsolate(call: MethodCall, result: Result) {
        var shellArgs: FlutterShellArgs? = null
        val mainActivity = getCurrentActivity()

        if (mainActivity != null) shellArgs = FlutterShellArgs.fromIntent(mainActivity.intent)

        if (backgroundFlutterEngine != null) {
            PowerAuthLogger.debug { "The background isolate is already running" }
            return
        }

        val loader = FlutterInjector.instance().flutterLoader()
        val mainHandler = Handler(Looper.getMainLooper())

        val myRunnable =
            Runnable {
                loader.startInitialization(context.applicationContext)
                loader.ensureInitializationCompleteAsync(
                    context.applicationContext,
                    null,
                    mainHandler
                ) {
                    backgroundFlutterEngine = FlutterEngine(context.applicationContext, shellArgs?.toArray())
                }
            }

        mainHandler.post(myRunnable)

        result.success(null)
    }

    fun removeBackgroundIsolate(call: MethodCall, result: Result) {
        clearFlutterEngine()
        result.success(null)
    }

    override fun cleanUp() {
        // Clean up the background isolate if it exists
        clearFlutterEngine()
        super.cleanUp()
    }

    private fun clearFlutterEngine() {
        backgroundFlutterEngine?.destroy()
        backgroundFlutterEngine = null
    }
}