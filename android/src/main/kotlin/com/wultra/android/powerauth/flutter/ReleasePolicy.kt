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
 * The `ReleasePolicy` class defines how an object is released automatically from the register.
 */
sealed class ReleasePolicy(private val type: Int, internal val param: Int = 0) {

    internal fun getPolicyType(): Int = type
    internal fun getPolicyParam(): Int = param

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is ReleasePolicy) return false
        return type == other.type && param == other.param
    }

    override fun hashCode(): Int {
        return 31 * type + param
    }

    object Manual : ReleasePolicy(TYPE_MANUAL)
    class AfterUse(count: Int) : ReleasePolicy(TYPE_AFTER_USE, count) {
        init {
            require(count > 0) { "AfterUse policy count must be positive." }
        }
    }

    class KeepAlive(timeIntervalMs: Int) : ReleasePolicy(TYPE_KEEP_ALIVE, timeIntervalMs) {
        init {
            require(timeIntervalMs > 0) { "KeepAlive timeIntervalMs must be positive." }
        }
    }

    class Expire(timeIntervalMs: Int) : ReleasePolicy(TYPE_EXPIRE, timeIntervalMs) {
        init {
            require(timeIntervalMs > 0) { "Expire timeIntervalMs must be positive." }
        }
    }

    companion object {
        internal const val TYPE_MANUAL = 0
        internal const val TYPE_AFTER_USE = 1
        internal const val TYPE_KEEP_ALIVE = 2
        internal const val TYPE_EXPIRE = 3

        /**
         * Creates a new release policy configured to a manual release. This type of policy
         * cannot be combined with other policy types, because the object owner manages the object's
         * lifetime.
         */
        @JvmStatic
        fun manual(): ReleasePolicy = Manual

        /**
         * Creates a new release policy configured to release object after expected amount of use.
         * It's recommended to combine this type of policy with `expire()` to make sure
         * that object is always released from the memory.
         * @param count Maximum number of object use allowed.
         */
        @JvmStatic
        fun afterUse(count: Int): ReleasePolicy = AfterUse(count)

        /**
         * Creates a new release policy configured to release object after a required time of inactivity.
         * The inactivity means that no interaction with the object occurred in the defined time window.
         * @param timeIntervalMs Time interval in milliseconds to keep object alive from last use attempt.
         */
        @JvmStatic
        fun keepAlive(timeIntervalMs: Int): ReleasePolicy = KeepAlive(timeIntervalMs)

        /**
         * Creates a new release policy configured to release object after a required time.
         * @param timeIntervalMs Time interval in milliseconds to keep object alive from its creation.
         */
        @JvmStatic
        fun expire(timeIntervalMs: Int): ReleasePolicy = Expire(timeIntervalMs)
    }
}
