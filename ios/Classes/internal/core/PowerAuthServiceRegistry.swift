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
internal class PowerAuthServiceRegistry {

    // MARK: - Singleton access

    private init() {}

    private static var _shared: PowerAuthServiceRegistry?

    private static let _lock = Lock()

    internal static var shared: PowerAuthServiceRegistry {
        _lock.synchronized {
            if let existing = _shared {
                return existing
            }
            let created = PowerAuthServiceRegistry()
            _shared = created
            return created
        }
    }

    private let objectRegister = PowerAuthObjectRegister()

    private func cleanUp() {
        objectRegister.removeAll()
    }

    // MARK: - Plugin attachment tracking

    private static var _attachmentCount: Int = 0

    internal static func onPluginAttached() {
        _lock.synchronized {
            _attachmentCount += 1
        }
    }

    internal static func onPluginDetached() {
        _lock.synchronized {
            _attachmentCount = max(0, _attachmentCount - 1)
            
            assert(_attachmentCount > 0, "PowerAuthServiceRegistry: Detach called more times than attach.")

            // If no more plugins / engines are attached, we can clean up.
            if _attachmentCount == 0 {
                _shared?.cleanUp()
            }
        }
    }

    internal static var attachmentCount: Int {
        _lock.synchronized { _attachmentCount }
    }

    // MARK: - Internals

    private lazy var services: [any PowerAuthFlutterService] = {
        return [
            PowerAuthService(register: objectRegister),
            PowerAuthUtilsService(),
            PowerAuthPasswordService(register: objectRegister),
            PowerAuthEncryptorService(register: objectRegister),
            PowerAuthRegisterService(register: objectRegister),
            PowerAuthLoggingService(),
            PowerAuthBackgroundIsolateService()
        ]
    }()

    internal lazy var handlers: [String: (service: any PowerAuthFlutterService, handler: Any)] = {
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
