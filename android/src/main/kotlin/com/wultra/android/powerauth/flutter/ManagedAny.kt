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

/**
 * A generic wrapper for objects stored in [PowerAuthObjectRegister]
 * that implements [IManagedObject].
 */
class ManagedAny<T: Any> private constructor(
    private val instance: T,
    private val cleanupAction: ((T) -> Unit)? = null
) : IManagedObject<T> {

    override fun cleanup() {
        cleanupAction?.invoke(instance)
    }

    override fun managedInstance(): T {
        return instance
    }

    companion object {
        /**
         * Wraps an object into an [IManagedObject].
         *
         * @param instance The object instance to wrap.
         * @param cleanupAction An optional lambda to be called when the object is cleaned up.
         * @return An [IManagedObject] wrapping the instance.
         */
        @JvmStatic
        fun <T: Any> wrap(instance: T, cleanupAction: ((T) -> Unit)? = null): IManagedObject<T> {
            return ManagedAny(instance, cleanupAction)
        }
    }
}
