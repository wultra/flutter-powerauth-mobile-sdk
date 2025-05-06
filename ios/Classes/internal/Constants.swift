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

internal class Constants {
    
    /// Time interval in milliseconds to keep pre-authorized biometric
    /// key in memory.
    static let BIOMETRY_KEY_KEEP_ALIVE_TIME: Int = 10_000

    /// Time interval in milliseconds to keep password object valid
    /// in memory.
    static let PASSWORD_KEY_KEEP_ALIVE_TIME: Double = 5 * 60 * 1_000

    /// Time interval in milliseconds to keep encryptor object alive in memory
    static let ENCRYPTOR_KEEP_ALIVE_TIME: Double = 5 * 60 * 1_000
    /// Time interval in milliseconds to keep decryptor object alive in memory
    static let DECRYPTOR_KEEP_ALIVE_TIME: Double = 5 * 60 * 1_000

    /// Upper limit for Unicode Code Point
    static let CODEPOINT_MAX = 0x10FFFF

    /// Default period in milliseconds for automatic objects cleanup job.
    static let CLEANUP_PERIOD_DEFAULT: Int = 10_000
    /// Minimum allowed period for automatic objects cleanup job.
    static let CLEANUP_PERIOD_MIN: Int = 100
    /// Maximum allowed period for automatic objects cleanup job.
    static let CLEANUP_PERIOD_MAX: Int = 60_000

}
