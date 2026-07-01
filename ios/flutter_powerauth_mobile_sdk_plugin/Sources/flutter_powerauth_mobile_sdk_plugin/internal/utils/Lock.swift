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

import Foundation

internal class Lock {
    
    /// Underlying synchronization primitive.
    private let semaphore: DispatchSemaphore
    
    /// Designated initializer
    init() {
        semaphore = DispatchSemaphore(value: 1)
    }
    
    /// Attempts to acquire a lock, blocking a thread’s execution
    /// until the lock can be acquired.
    func lock() {
        semaphore.wait()
    }
    
    /// Releases a previously acquired lock.
    func unlock() {
        semaphore.signal()
    }
    
    /// Executes block after lock is acquired and releases it immediately afterwards.
    /// - Parameter block: block that will be executed during the lock
    /// - Returns: returns the output pf the block
    func synchronized<T>(_ block: () -> T) -> T {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        return block()
    }
}
