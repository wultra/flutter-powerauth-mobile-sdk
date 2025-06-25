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

import android.os.SystemClock
import android.util.Base64
import com.wultra.android.powerauth.flutter.Constants.CLEANUP_PERIOD_DEFAULT
import com.wultra.android.powerauth.flutter.Constants.CLEANUP_PERIOD_MAX
import com.wultra.android.powerauth.flutter.Constants.CLEANUP_PERIOD_MIN
import com.wultra.android.powerauth.flutter.Constants.CLEANUP_REMOVE_DELAY
import java.util.Random
import java.util.Timer
import java.util.TimerTask
import java.util.concurrent.locks.ReentrantLock
import kotlin.collections.ArrayList
import kotlin.concurrent.withLock
import io.getlime.security.powerauth.core.Password
import java.nio.charset.StandardCharsets

/**
 * Object register that allows exposing native objects.
 * The object is identified by a unique identifier created at the time of registration
 * or by an application-provided identifier.
 */
class PowerAuthObjectRegister private constructor(private val isDebug: Boolean) {

    companion object {
        @Volatile
        private var INSTANCE: PowerAuthObjectRegister? = null

        @Volatile
        private var attachmentCount = 0

        private const val OPT_NONE = 0
        private const val OPT_SET_USE = 1
        private const val OPT_TOUCH = 2
        private const val OPT_REMOVE = 3

        @JvmStatic
        fun getInstance(isDebug: Boolean = false): PowerAuthObjectRegister {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: PowerAuthObjectRegister(isDebug).also { INSTANCE = it }
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

                // If no more plugins / engines are attached, we can clean up the register.
                // TODO: do we want to keep the singleton instance for potential re-init?
                if (attachmentCount == 0) {
                    INSTANCE?.removeAllObjects()
                }
            }
        }


        // For testing purposes - TODO: remove before release
        @JvmStatic
        internal fun resetForTesting() {
            synchronized(this) {
                INSTANCE?.removeAllObjects()
                INSTANCE = null
                attachmentCount = 0
            }
        }

        @JvmStatic
        internal fun getAttachmentCount(): Int {
            synchronized(this) {
                return attachmentCount
            }
        }
    }

    private val lock = ReentrantLock(false)
    private val managedObjects = mutableMapOf<String, ManagedObjectHolder>()
    private val randomGenerator: Random = Random()
    private var cleanupTimer: Timer? = null
    private var cleanupPeriodMs: Long = CLEANUP_PERIOD_DEFAULT.toLong()

    /**
     * Factory that creates an object on demand.
     */
    fun interface ObjectFactory<T : Any> {
        @Throws(Throwable::class)
        fun create(): IManagedObject<T>
    }

    private class ManagedObjectHolder(
        val obj: IManagedObject<out Any>,
        val tag: String?,
        policies: List<ReleasePolicy>,
        val creationTime: Long = SystemClock.elapsedRealtime(),
        var lastUseTime: Long = creationTime,
        var useCount: Int = 0,
        var removeOrderTime: Long = 0
    ) {
        // TODO: improve
        val policies = if (policies.contains(ReleasePolicy.manual())) null else policies

        fun setUsed() {
            lastUseTime = SystemClock.elapsedRealtime()
            useCount++
        }

        fun touch() {
            lastUseTime = SystemClock.elapsedRealtime()
        }

        /**
         * Marks object as removed and return information whether object can be removed immediately.
         */
        fun setRemoved(): Boolean {
            removeOrderTime = SystemClock.elapsedRealtime()
            // If policies is null then the object is manually managed, so it should be removed immediately.
            return policies == null
        }

        // TODO: refactor the null-defaulting into this if it makes sense
        val isManuallyManaged: Boolean
            get() {
                return (policies?.contains(ReleasePolicy.manual()) == true)
            }

        /**
         * Determine whether this native object is still valid.
         */
        val isStillValid: Boolean
            get() {
                if (removeOrderTime != 0L) {
                    return false
                }

                if (policies == null) {
                    return true
                }

                val currentTime = SystemClock.elapsedRealtime()
                policies.forEach { rp ->
                    val param = rp.getPolicyParam()

                    when (rp.getPolicyType()) {
                        ReleasePolicy.TYPE_AFTER_USE -> if (useCount >= param) return false
                        ReleasePolicy.TYPE_KEEP_ALIVE -> if (currentTime - lastUseTime >= param.toLong()) return false
                        ReleasePolicy.TYPE_EXPIRE -> if (currentTime - creationTime >= param.toLong()) return false
                    }
                }

                return true
            }

        /**
         * Determine whether object can be removed from the register.
         */
        val isReadyForRemove: Boolean
            get() {
                if (isStillValid) {
                    return false
                }

                // If removeOrderTime is 0, then object was not explicitly removed.
                // This means that object is expired or was used for a limited number of times.
                // On other side, if time is specified then the object was explicitly removed, so
                // it should be ready for remove after a short delay period.
                val readyNow =
                    removeOrderTime == 0L || (SystemClock.elapsedRealtime() - removeOrderTime >= CLEANUP_REMOVE_DELAY.toLong())

                if (readyNow) {
                    obj.cleanup()
                }

                return readyNow
            }

        fun debugDump(): Map<String, Any?> {
            return mapOf(
                "class" to obj.managedInstance()::class.java.simpleName,
                "isValid" to isStillValid,
                "tag" to tag,
                "createDate" to creationTime,
                "lastUseDate" to if (lastUseTime != creationTime) lastUseTime else null,
                "usageCount" to useCount,
                "policies" to (policies?.map { it.toString() } ?: emptyList())
            )
        }
    }

    /**
     * Registers an object and returns its unique identifier.
     */
    fun <T : Any> registerObject(
        objectWrapper: IManagedObject<T>,
        tag: String?,
        releasePolicies: List<ReleasePolicy>
    ): String = lock.withLock {
        val id = generateId()

        managedObjects[id] = ManagedObjectHolder(objectWrapper, tag, releasePolicies)
        scheduleCleanupJob()

        return@withLock id
    }

    /**
     * Registers an object with an application-provided identifier.
     */
    fun <T : Any> registerObjectWithId(
        id: String,
        objectWrapper: IManagedObject<T>,
        tag: String?,
        releasePolicies: List<ReleasePolicy>
    ): Boolean = lock.withLock {
        if (!isValidObjectId(id) || managedObjects.containsKey(id)) {
            return@withLock false
        }

        managedObjects[id] = ManagedObjectHolder(objectWrapper, tag, releasePolicies)
        scheduleCleanupJob()

        return@withLock true
    }

    /**
     * Registers an object provided by a factory with an application-provided identifier.
     */
    @Throws(Throwable::class)
    fun <T : Any> registerObjectWithId(
        id: String,
        tag: String?,
        releasePolicies: List<ReleasePolicy>,
        factory: ObjectFactory<T>
    ): Boolean = lock.withLock {
        if (!isValidObjectId(id) || managedObjects.containsKey(id)) {
            return@withLock false
        }

        val objectWrapper = factory.create()

        managedObjects[id] = ManagedObjectHolder(objectWrapper, tag, releasePolicies)
        scheduleCleanupJob()

        return@withLock true
    }

    /**
     * Find object with given identifier and do an additional operation with the object.
     * @param id Object identifier.
     * @param expectedClass Expected class, or null if any object can be returned (in case of remove)
     * @param options Additional operation that should be performed with the object's entry. Use `OPT_*` constants.
     * @param <T> Expected object's type.
     * @return instance of object with given identifier or null if no such object exists in register.
    </T> */
    private fun <T : Any> findAndProcessObject(
        id: String?,
        expectedClass: Class<T>?,
        options: Int
    ): T? {
        val objectId = id ?: return null
        val holder = managedObjects[objectId] ?: return null

        val instance = holder.obj.managedInstance()

        if (!holder.isStillValid ||
            (expectedClass != null && !expectedClass.isInstance(instance))
        ) return null

        when (options) {
            OPT_SET_USE -> holder.setUsed()
            OPT_TOUCH -> holder.touch()
            OPT_REMOVE -> if (holder.setRemoved()) {
                holder.obj.cleanup()
                managedObjects.remove(id)
            }
        }

        @Suppress("UNCHECKED_CAST")
        return instance as T
    }

    fun <T : Any> findObject(id: String, type: Class<T>): T? = lock.withLock {
        return findAndProcessObject(id, type, OPT_NONE)
    }

    fun <T : Any> useObject(id: String, type: Class<T>): T? = lock.withLock {
        return findAndProcessObject(id, type, OPT_SET_USE)
    }

    fun <T : Any> touchObject(id: String, type: Class<T>): T? = lock.withLock {
        return findAndProcessObject(id, type, OPT_TOUCH)
    }

    fun <T : Any> removeObject(id: String, type: Class<T>): T? = lock.withLock {
        return@withLock findAndProcessObject(id, type, OPT_REMOVE)
    }

    /**
     * Removes all objects associated with a specific tag.
     * If tag is null, removes all objects that are not manually managed.
     */
    fun removeAllObjectsWithTag(tag: String?) = lock.withLock {
        val iterator = managedObjects.entries.iterator()
        var changed = false
        while (iterator.hasNext()) {
            val entry = iterator.next()
            val holder = entry.value

            // TODO: implement proper filtering!
            if (tag == null || holder.tag == tag) {
                if (holder.setRemoved()) {
                    holder.obj.cleanup()
                    iterator.remove()

                    changed = true
                } else if (holder.isReadyForRemove) {
                    iterator.remove()
                    changed = true
                } else {
                    // marked for later cleanup, ensure a job is scheduled
                    changed = true
                }
            }
        }

        if (changed) scheduleCleanupJob()
    }

    /**
     * Removes all objects from the register, regardless of policy.
     */
    internal fun removeAllObjects() = lock.withLock {
        managedObjects.values.forEach { it.obj.cleanup() }
        managedObjects.clear()
        stopCleanupJob()
    }

    fun isValidObjectId(id: String?): Boolean {
        return !id.isNullOrEmpty()
    }

    private fun setCleanupPeriod(periodMs: Long) = lock.withLock {
        cleanupPeriodMs = if (periodMs in CLEANUP_PERIOD_MIN..CLEANUP_PERIOD_MAX) {
            periodMs
        } else {
            CLEANUP_PERIOD_DEFAULT.toLong()
        }

        if (cleanupTimer != null) {
            stopCleanupJob()
            startCleanupJob()
        }
    }

    private fun generateId(): String {
        val numberOfBytes = 3 * (3 + randomGenerator.nextInt(6))
        val randomBytes = ByteArray(numberOfBytes)

        while (true) {
            randomGenerator.nextBytes(randomBytes)
            val id = Base64.encodeToString(randomBytes, Base64.NO_WRAP)

            if (!managedObjects.containsKey(id)) {
                return id
            }
        }
    }

    /** Schedule an object cleanup job. */
    private fun scheduleCleanupJob() = lock.withLock {
        if (managedObjects.isNotEmpty()) {
            if (cleanupTimer == null) {
                cleanupTimer = Timer("PowerAuthObjectRegisterTimer")
                startCleanupJob()
            }
        } else {
            stopCleanupJob()
        }
    }

    private fun startCleanupJob() {
        if (cleanupTimer == null) return

        try {
            cleanupTimer?.schedule(object : TimerTask() {
                override fun run() {
                    lock.withLock { performCleanup() }
                }
            }, cleanupPeriodMs, cleanupPeriodMs)
        } catch (_: IllegalStateException) {
        }
    }

    private fun stopCleanupJob() {
        cleanupTimer?.cancel()
        cleanupTimer?.purge()
        cleanupTimer = null
    }

    /** Function remove expired or no longer valid objects from the register. */
    private fun performCleanup() = lock.withLock {
        val idsToRemove = ArrayList<String>()
        managedObjects.forEach { (id, holder) ->
            if (holder.isReadyForRemove) {
                idsToRemove.add(id)
            }
        }

        if (idsToRemove.isNotEmpty()) {
            idsToRemove.forEach { managedObjects.remove(it) }
        }

        scheduleCleanupJob()
    }

    // Called by PowerAuthPlugin when detaching from Flutter
    fun invalidate() {
        lock.withLock {
            removeAllObjects()
        }
    }

    fun debugDumpObjectsWithTag(tag: String?): List<Map<String, Any?>> {
        if (!isDebug) {
            return emptyList()
        }

        return lock.withLock {
            val result = mutableListOf<Map<String, Any?>>()
            for ((key, value) in managedObjects) {
                if (tag == null || tag == value.tag) {
                    val dump = value.debugDump().toMutableMap()
                    dump["id"] = key
                    result.add(dump)
                }
            }

            return@withLock result
        }
    }

    fun debugCommand(command: String, data: Map<String, Any>): Any? {
        if (!isDebug) {
            return null
        }

        val objectId = data["objectId"] as? String
        when (command) {
            "create" -> {
                val objectType = data["objectType"] as? String
                val objectTag = data["objectTag"] as? String
                val releasePolicyDescription = data["releasePolicy"] as? List<String>

                val policies = mutableListOf<ReleasePolicy>()

                if (releasePolicyDescription != null) {
                    for (policy in releasePolicyDescription) {
                        val components = policy.split(" ".toRegex()).toTypedArray()
                        val param = if (components.size > 1) components[1].toInt() else 1

                        when {
                            policy.startsWith("manual") -> policies.add(ReleasePolicy.manual())
                            policy.startsWith("afterUse") -> policies.add(
                                ReleasePolicy.afterUse(
                                    param
                                )
                            )

                            policy.startsWith("keepAlive") -> policies.add(
                                ReleasePolicy.keepAlive(
                                    param
                                )
                            )

                            policy.startsWith("expire") -> policies.add(ReleasePolicy.expire(param))
                        }
                    }
                }

                if (policies.isNotEmpty()) {
                    val newObject: IManagedObject<out Any>? = when (objectType) {
                        "data" -> {
                            val td = "TEST-DATA".toByteArray(StandardCharsets.UTF_8)
                            ManagedAny.wrap(td, null)
                        }

                        "secureData" -> {
                            val td = "SECURE-DATA".toByteArray(StandardCharsets.UTF_8)
                            ManagedAny.wrap(td)
                        }

                        "number" -> ManagedAny.wrap(42)
                        "password" -> ManagedAny.wrap(
                            Password(),
                            cleanupAction = { password -> password.destroy() })

                        else -> null
                    }
                    if (newObject != null) {
                        return registerObject(newObject, objectTag, policies)
                    }
                }

                return null
            }

            "release" -> {
                val objectIdNonNull = objectId ?: throw WrapperException(
                    Errors.EC_WRONG_PARAMETER,
                    "Missing objectId"
                )
                val objectType = data["objectType"] as? String
                val clazz = getClassForObjectType(objectType)
                    ?: throw WrapperException(Errors.EC_WRONG_PARAMETER, "Unknown objectType")
                val removedInstance = removeObject(objectIdNonNull, clazz)

                return removedInstance != null
            }

            "releaseAll" -> {
                val tag = data["objectTag"] as? String
                removeAllObjectsWithTag(tag)

                return null
            }

            "use" -> {
                val objectIdNonNull = objectId ?: throw WrapperException(
                    Errors.EC_WRONG_PARAMETER,
                    "Missing objectId"
                )
                val objectType = data["objectType"] as? String
                val clazz = getClassForObjectType(objectType)
                    ?: throw WrapperException(Errors.EC_WRONG_PARAMETER, "Unknown objectType")

                return useObject(objectIdNonNull, clazz) != null
            }

            "find" -> {
                val objectIdNonNull = objectId ?: throw WrapperException(
                    Errors.EC_WRONG_PARAMETER,
                    "Missing objectId"
                )
                val objectType = data["objectType"] as? String
                val clazz = getClassForObjectType(objectType)
                    ?: throw WrapperException(Errors.EC_WRONG_PARAMETER, "Unknown objectType")

                return findObject(objectIdNonNull, clazz) != null
            }

            "touch" -> {
                val objectIdNonNull = objectId ?: throw WrapperException(
                    Errors.EC_WRONG_PARAMETER,
                    "Missing objectId"
                )
                val objectType = data["objectType"] as? String
                val clazz = getClassForObjectType(objectType)
                    ?: throw WrapperException(Errors.EC_WRONG_PARAMETER, "Unknown objectType")

                return touchObject(objectIdNonNull, clazz) != null
            }

            "setPeriod" -> {
                val period = data["cleanupPeriod"] as? Int
                if (period != null) {
                    setCleanupPeriod(period.toLong())
                }

                return null
            }

            else -> throw WrapperException(
                Errors.EC_WRONG_PARAMETER,
                "Unsupported debug command: $command"
            )
        }
    }

    private fun getClassForObjectType(objectType: String?): Class<out Any>? {
        return when (objectType) {
            "data", "secureData" -> ByteArray::class.java
            "number" -> Number::class.java
            "password" -> Password::class.java
            else -> null
        }
    }
}
