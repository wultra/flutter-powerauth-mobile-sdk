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

package com.wultra.android.powerauth.flutter.internal.core

import android.app.Activity
import android.content.Context
import androidx.fragment.app.FragmentActivity
import com.wultra.android.powerauth.flutter.PowerAuthObjectRegister
import com.wultra.android.powerauth.flutter.internal.services.*
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthBackgroundIsolateService
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthEncryptorService
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthPasswordService
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthRegisterService
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthService
import com.wultra.android.powerauth.flutter.internal.services.PowerAuthUtilsService
import com.wultra.android.powerauth.flutter.internal.utils.PowerAuthLogger
import io.flutter.BuildConfig
import java.lang.ref.WeakReference

/**
 * Singleton registry for PowerAuth services.
 *
 * This registry is responsible for managing the lifecycle of PowerAuth services and
 * providing access to them.
 *
 * There is a single instance of this registry, and it is created
 * when the first plugin is attached. This is to prevent plugins (each isolate can have its own instance)
 * from creating multiple instances of the registry, which could lead to conflicts and unexpected
 * PowerAuth states.
 */
@Suppress("unused")
class PowerAuthServiceRegistry private constructor(appContext: Context) {

    companion object {
        @Volatile
        private var INSTANCE: PowerAuthServiceRegistry? = null

        @Volatile
        private var attachmentCount = 0

        @JvmStatic
        fun getInstance(appContext: Context): PowerAuthServiceRegistry {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: PowerAuthServiceRegistry(appContext).also { INSTANCE = it }
            }
        }

        @JvmStatic
        internal fun onPluginAttached() {
            synchronized(this) {
                attachmentCount++
            }
        }

        @JvmStatic
        internal fun onPluginDetached() {
            synchronized(this) {
                attachmentCount = maxOf(0, attachmentCount - 1)

                // If no more plugins / engines are attached, we can clean up.
                // TODO: do we want to keep the singleton instance for potential re-init?
                if (attachmentCount == 0) {
                    INSTANCE?.let { instance ->
                        instance.services.forEach {
                            it.value.cleanUp()
                        }
                        instance.objectRegister.cleanup()
                    }
                }
            }
        }

        @JvmStatic
        internal fun getAttachmentCount(): Int {
            synchronized(this) {
                return attachmentCount
            }
        }
    }

    private val objectRegister = PowerAuthObjectRegister(BuildConfig.DEBUG)
    private val services = mutableMapOf<String, PowerAuthFlutterService>()
    private val activities = FragmentActivityWeakList()

    init {
        registerAll(
            PowerAuthService(objectRegister, appContext, getCurrentActivity = { activities.getFirstAvailable() }),
            PowerAuthPasswordService(objectRegister),
            PowerAuthUtilsService(appContext),
            PowerAuthCoreCryptoUtilsService(),
            PowerAuthEncryptorService(objectRegister, appContext),
            PowerAuthRegisterService(objectRegister),
            PowerAuthLoggingService(),
            PowerAuthBackgroundIsolateService(appContext, getCurrentActivity = { activities.getFirstAvailable() })
        )
    }

    operator fun get(name: String): PowerAuthFlutterService? = services[name]

    private fun registerAll(vararg servicesToAdd: PowerAuthFlutterService) {
        servicesToAdd.forEach {
            services[it.name] = it
        }
    }

    fun addActivity(activity: Activity) {
        if (activity !is FragmentActivity) {
            PowerAuthLogger.error { "Attached Android Activity is not a FragmentActivity, which is required for use." }
            return
        }
        activities.add(activity)
    }
}

/**
 * A thread-safe list of weak references to FragmentActivity instances.
 * This allows us to keep track of the currently active FragmentActivity
 * without preventing it from being garbage collected.
 */
private class FragmentActivityWeakList {

    private val list = ArrayList<WeakReference<FragmentActivity>>()
    private val lock = Any()

    fun add(activity: FragmentActivity) {
        synchronized(lock) {
            clearEmpty() // when adding a new activity, clean up stale references
            list.add(0, WeakReference(activity)) // Add to the front
        }
    }

    fun getFirstAvailable(): FragmentActivity? {
        synchronized(lock) {
            clearEmpty() // Clean up stale references before accessing
            return list.firstOrNull()?.get() // return first activity in the list
        }
    }

    private fun clearEmpty() {
        val iterator = list.iterator()
        while (iterator.hasNext()) {
            val activity = iterator.next().get()
            if (activity == null || activity.isFinishing || activity.isDestroyed) {
                iterator.remove() // Remove stale references
            }
        }
    }
}
