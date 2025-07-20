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

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.EventChannel
import io.getlime.security.powerauth.system.PowerAuthLog
import io.getlime.security.powerauth.system.PowerAuthLogListener

/**
 * An enumeration of all possible logging levels used in the PowerAuth SDK.
 */
enum class PowerAuthLogLevel {
    VERBOSE,
    DEBUG,
    INFO,
    WARNING,
    ERROR
}

/**
 * A simple logger for internal SDK usage.
 */
object PowerAuthLogger: EventChannel.StreamHandler, PowerAuthLogListener {

    private val mainThreadHandler = Handler(Looper.getMainLooper())

    init {
        // Register this logger as a listener for the native PowerAuth SDK logs
        PowerAuthLog.logListener = this
    }

    /** The current logging level. */
    var level: PowerAuthLogLevel = PowerAuthLogLevel.INFO
        set(value) {
            field = value
            updateNativeSdkLogging()
        }

    /** Determines whether logging is enabled. */
    var enabled: Boolean = true
        set(value) {
            field = value
            updateNativeSdkLogging()
        }

    /** Logs a verbose message. */
    fun verbose(message: () -> String) = log(PowerAuthLogLevel.VERBOSE, message)

    /** Logs a debug message. */
    fun debug(message: () -> String) = log(PowerAuthLogLevel.DEBUG, message)

    /** Logs an info message. */
    fun info(message: () -> String) = log(PowerAuthLogLevel.INFO, message)

    /** Logs a warning message. */
    fun warning(message: () -> String) = log(PowerAuthLogLevel.WARNING, message)

    /** Logs an error message. */
    fun error(message: () -> String) = log(PowerAuthLogLevel.ERROR, message)

    // PowerAuthLogListener implementation
    override fun powerAuthDebugLog(message: String) {
        log(PowerAuthLogLevel.DEBUG, { message }, "PowerAuthNativeSDK")
    }

    override fun powerAuthWarningLog(message: String) {
        log(PowerAuthLogLevel.WARNING, { message }, "PowerAuthNativeSDK")
    }

    override fun powerAuthErrorLog(message: String) {
        log(PowerAuthLogLevel.ERROR, { message }, "PowerAuthNativeSDK")
    }

    private fun updateNativeSdkLogging() {
        val shouldEnable = enabled && level.ordinal <= PowerAuthLogLevel.DEBUG.ordinal
        val isVerbose = shouldEnable && level.ordinal == PowerAuthLogLevel.VERBOSE.ordinal

        PowerAuthLog.setEnabled(shouldEnable)
        PowerAuthLog.setVerbose(isVerbose)
    }

    /** Central logging method. */
    private fun log(messageLevel: PowerAuthLogLevel, message: () -> String, tag: String? = null) {
        if (!enabled || level.ordinal > messageLevel.ordinal) {
            return
        }
        val logMessage = message()

        val priority = when (messageLevel) {
            PowerAuthLogLevel.VERBOSE -> Log.VERBOSE
            PowerAuthLogLevel.DEBUG -> Log.DEBUG
            PowerAuthLogLevel.INFO -> Log.INFO
            PowerAuthLogLevel.WARNING -> Log.WARN
            PowerAuthLogLevel.ERROR -> Log.ERROR
        }

        Log.println(priority, "PowerAuthSDK", logMessage)

        val logData = mapOf(
            "level" to messageLevel.name.lowercase(),
            "message" to logMessage,
            "tag" to (tag ?: "PowerAuthSDK")
        )

        mainThreadHandler.post {
            eventSink?.success(logData)
        }
    }

    private var eventSink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
} 