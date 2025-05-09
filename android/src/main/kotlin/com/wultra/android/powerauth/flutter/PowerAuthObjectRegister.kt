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

/**
 * Object register that allows exposing native objects.
 * The object is identified by a unique identifier created at the time of registration
 * or by an application-provided identifier.
 */
class PowerAuthObjectRegister {

    private val lock = ReentrantLock(false)
    private val managedObjects = mutableMapOf<String, ManagedObjectHolder>()
    private val randomGenerator: Random = Random()
    private var cleanupTimer: Timer? = null
    private var cleanupPeriodMs: Long = CLEANUP_PERIOD_DEFAULT.toLong()

    /**
     * Factory that creates an object on demand.
     */
    fun interface ObjectFactory<T: Any> {
        @Throws(Throwable::class)
        fun create(): IManagedObject<T>
    }

    private data class ManagedObjectHolder(
        val obj: IManagedObject<out Any>,
        val tag: String?,
        val policies: List<ReleasePolicy>?,
        val creationTime: Long = SystemClock.elapsedRealtime(),
        var lastUseTime: Long = creationTime,
        var useCount: Int = 0,
        var removeOrderTime: Long = 0
    ) {
        val isManuallyManaged: Boolean = policies == null

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
                val readyNow = removeOrderTime == 0L || (SystemClock.elapsedRealtime() - removeOrderTime >= CLEANUP_REMOVE_DELAY.toLong())

                if (readyNow) {
                    obj.cleanup()
                }

                return readyNow
            }
    }

    /**
     * Registers an object and returns its unique identifier.
     */
    fun <T: Any> registerObject(
        objectWrapper: IManagedObject<T>,
        tag: String?,
        releasePolicies: List<ReleasePolicy>
    ): String = lock.withLock {
        val id = generateId()

        managedObjects[id] = ManagedObjectHolder(objectWrapper, tag, releasePolicies)
        scheduleCleanupJob()

        return id
    }

    /**
     * Registers an object with an application-provided identifier.
     */
    fun <T: Any> registerObjectWithId(
        id: String,
        objectWrapper: IManagedObject<T>,
        tag: String?,
        releasePolicies: List<ReleasePolicy>
    ): Boolean = lock.withLock {
        if (!isValidObjectId(id) || managedObjects.containsKey(id)) {
            return false
        }

        managedObjects[id] = ManagedObjectHolder(objectWrapper, tag, releasePolicies)
        scheduleCleanupJob()

        return true
    }

    /**
     * Registers an object provided by a factory with an application-provided identifier.
     */
    @Throws(Throwable::class)
    fun <T: Any> registerObjectWithId(
        id: String,
        tag: String?,
        releasePolicies: List<ReleasePolicy>,
        factory: ObjectFactory<T>
    ): Boolean = lock.withLock {
        if (!isValidObjectId(id) || managedObjects.containsKey(id)) {
            return false
        }

        val objectWrapper = factory.create()

        managedObjects[id] = ManagedObjectHolder(objectWrapper, tag, releasePolicies)
        scheduleCleanupJob()

        return true
    }

    /**
     * Find object with given identifier and do an additional operation with the object.
     * @param id Object identifier.
     * @param expectedClass Expected class, or null if any object can be returned (in case of remove)
     * @param options Additional operation that should be performed with the object's entry. Use `OPT_*` constants.
     * @param <T> Expected object's type.
     * @return instance of object with given identifier or null if no such object exists in register.
    </T> */
    private fun <T: Any> findAndProcessObject(id: String?, expectedClass: Class<T>, options: Int): T? {
        val objectId = id ?: return null
        val holder = managedObjects[objectId]

        if (holder != null) {
            val instance = holder.obj.managedInstance()

            if (expectedClass.isInstance(instance)) {
                if (holder.isStillValid) {
                    when (options) {
                        OPT_SET_USE -> holder.setUsed()
                        OPT_TOUCH -> holder.touch()
                        OPT_REMOVE -> {
                            if (holder.setRemoved()) {
                                holder.obj.cleanup()
                                managedObjects.remove(objectId)
                            }
                        }
                    }
                    // TODO: seems like if after OPT_SET_USE, the object became invalid (e.g. AfterUse(1)), remove it -- verify
                    if (options == OPT_SET_USE && !holder.isStillValid && holder.isReadyForRemove) {
                        managedObjects.remove(objectId)
                    }

                    @Suppress("UNCHECKED_CAST")
                    return instance as T
                }
            }
        }

        return null
    }

    fun <T : Any> findObject(id: String, type: Class<T>): T? = lock.withLock {
        findAndProcessObject(id, type, OPT_NONE)
    }

    fun <T : Any> useObject(id: String, type: Class<T>): T? = lock.withLock {
        val obj = findAndProcessObject(id, type, OPT_SET_USE)

        // Hypothesis (c0mtru1se) on the need for this explicit cleanup (gotta confirm this before release!)
        // scheduleCleanupJob is called from findAndProcessObject's OPT_SET_USE if object is removed immediately
        // and also after any explicit removal in removeObject
        // If findAndProcessObject removed it, scheduleCleanupJob() would be called there if needed for other objects.
        // If it wasn't removed, but use changed policies, cleanup will catch it.
        // The main point is that scheduleCleanupJob() should run if the state of *any* object changes
        // such that it might need a timer start/stop.
        if (obj != null) scheduleCleanupJob()

        return obj
    }

    fun removeObject(id: String): Boolean = lock.withLock {
        val removedInstance = findAndProcessObject(id, Any::class.java, OPT_REMOVE)
        val wasPresent = managedObjects[id]?.removeOrderTime != 0L || !managedObjects.containsKey(id)

        // TODO: is this needed after every attempt?
        scheduleCleanupJob()

        return removedInstance != null || wasPresent
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

            if (tag == null || holder.tag == tag) {
                if (tag != null || !holder.isManuallyManaged) {
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
        }

        if (changed) scheduleCleanupJob()
    }

    /**
     * Removes all objects from the register, regardless of policy.
     */
    fun removeAllObjects() = lock.withLock {
        managedObjects.values.forEach { it.obj.cleanup() }
        managedObjects.clear()
        stopCleanupJob()
    }

    fun isValidObjectId(id: String?): Boolean {
        return !id.isNullOrEmpty()
    }

    fun setCleanupPeriod(periodMs: Long) = lock.withLock {
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
    internal fun scheduleCleanupJob() = lock.withLock {
        if (managedObjects.any { !it.value.isManuallyManaged && it.value.removeOrderTime == 0L }) {
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
        } catch (e: IllegalStateException) {
            // TODO: do we want to throw anything?
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

    companion object {
        private const val OPT_NONE = 0
        private const val OPT_SET_USE = 1
        private const val OPT_TOUCH = 2
        private const val OPT_REMOVE = 3
    }
}
