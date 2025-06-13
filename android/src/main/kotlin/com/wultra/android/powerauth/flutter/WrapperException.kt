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

// TODO: copy-paste from RN Java. Check later whether we want more metadata for Flutter.
/**
 * Exception type used internally in this module to propagate error code and message
 * to Flutter result.
 */
class WrapperException :
/**
 * Construct WrapperException with required error code and message.
 * @param errorCode Error code that should be reported to promise as failure.
 * @param message Message that should be reported to promise as failure.
 */
    Exception {

    val errorCode: String

    constructor(errorCode: String, message: String) : super(message, null) {
        this.errorCode = errorCode
    }

    /**
     * Construct WrapperException with required error code, message and optional cause of the failure.
     * @param errorCode Error code that should be reported to promise as failure.
     * @param message Message that should be reported to promise as failure.
     * @param cause Original cause of failure.
     */
    constructor(errorCode: String, message: String, cause: Throwable?) : super(message, cause) {
        this.errorCode = errorCode
    }
} 