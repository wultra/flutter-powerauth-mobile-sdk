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

object PowerAuthServiceRegistry {
    private val services = mutableMapOf<String, PowerAuthFlutterService>()

    operator fun plusAssign(service: PowerAuthFlutterService) {
        services[service.name] = service
    }

    operator fun get(name: String): PowerAuthFlutterService? = services[name]

    fun registerAll(vararg services: PowerAuthFlutterService) {
        services.forEach { this += it }
    }
}
