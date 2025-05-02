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

internal object Constants {
    /**
     * Default period in milliseconds for automatic objects cleanup job.
     */
    const val CLEANUP_PERIOD_DEFAULT = 10_000

    /**
     * Minimum allowed period for automatic objects cleanup job.
     */
    const val CLEANUP_PERIOD_MIN = 100

    /**
     * Maximum allowed period for automatic objects cleanup job.
     */
    const val CLEANUP_PERIOD_MAX = 60_000

    /**
     * Keep object in memory for one more second after the explicit remove.
     */
    const val CLEANUP_REMOVE_DELAY = 1_000

    /**
     * Time interval in milliseconds to keep pre-authorized biometric key in memory.
     */
    const val BIOMETRY_KEY_KEEP_ALIVE_TIME = 10_000

    /**
     * Time interval in milliseconds to keep password object valid in memory.
     */
    const val PASSWORD_KEY_KEEP_ALIVE_TIME = 5 * 60 * 1_000

    /**
     * Time interval in milliseconds to keep encryptor object valid in memory.
     */
    const val ENCRYPTOR_KEY_KEEP_ALIVE_TIME = 5 * 60 * 1_000

    /**
     * Time interval in milliseconds to keep decryptor object valid in memory.
     */
    const val DECRYPTOR_KEY_KEEP_ALIVE_TIME = 5 * 60 * 1_000

    /**
     * Upper limit for Unicode Code Point.
     */
    const val CODEPOINT_MAX = 0x10FFFF

    // Fallback strings
    /**
     * Fallback string used in biometric authentication when no title is
     * provided to authentication dialog.
     */
    const val MISSING_REQUIRED_STRING = "< missing >"
} 