/*
 * Copyright 2025 Wultra s.r.o.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation
import Flutter
import PowerAuth2
import PowerAuthCore

/// Singleton registry for PowerAuth services.
///
/// This registry is responsible for managing the lifecycle of PowerAuth services and
/// providing access to them.
///
/// There is a single instance of this registry, and it is created
/// when the first plugin is attached. This is to prevent plugins (each isolate can have its own instance)
/// from creating multiple instances of the registry, which could lead to conflicts and unexpected
/// PowerAuth states.
internal enum PowerAuthServiceRegistry {

    // MARK: - Synchronization

    private static let lock = Lock()

    // MARK: - Plugin attachment tracking

    private static var attachedPluginCount: Int = 0

    internal static func onPluginAttached() {
        lock.synchronized { attachedPluginCount += 1 }
    }

    internal static func onPluginDetached() {
        lock.synchronized {
            attachedPluginCount -= 1
            assert(attachedPluginCount >= 0, "PowerAuthServiceRegistry: Detach called more times than attach.")
            
            if attachedPluginCount == 0 {
                cleanUp()
            }
        }
    }

    // MARK: - Internals

    private static let objectRegister = PowerAuthObjectRegister()

    private static func cleanUp() {
        objectRegister.removeAll()
    }

    private static let services: [any PowerAuthFlutterService] = {
        return [
            PowerAuthService(register: objectRegister),
            PowerAuthUtilsService(),
            PowerAuthPasswordService(register: objectRegister),
            PowerAuthCoreCryptoUtilsService(),
            PowerAuthEncryptorService(register: objectRegister),
            PowerAuthRegisterService(register: objectRegister),
            PowerAuthLoggingService(),
            PowerAuthBackgroundIsolateService()
        ]
    }()

    internal static let handlers: [String: (service: any PowerAuthFlutterService, handler: Any)] = {
        var map = [String: (service: any PowerAuthFlutterService, handler: Any)]()
        services.forEach { service in
            service.opaqueHandlers.forEach { key, value in
                map[key] = (service, value)
            }
        }
        return map
    }()
}

// MARK: - Convenience helpers

private extension PowerAuthFlutterService {
    var opaqueHandlers: [String: Any] {
        return handlers.mapValues { $0 }
    }
}
