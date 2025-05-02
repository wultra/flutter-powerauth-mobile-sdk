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

internal class ReleasePolicy: Equatable {
    
    enum RPType: Int {
        case manual = 0
        case afterUse = 1
        case keepAlive = 2
        case expire = 3
    }
    
    private let value: Int
    
    private init(type: RPType, param: Int) {
        self.value = (type.rawValue & 0xF) | (param << 4)
    }
    
    /// Returns the policy type
    func getPolicyType() -> RPType {
        return RPType(rawValue: value & 0xF)!
    }
    
    /// Returns the policy parameter.
    func getPolicyParam() -> Int {
        return value >> 4
    }
    
    /// Creates a new release policy configured for manual release.
    /// This type of policy cannot be combined with other policy types, as the object owner manages the object's lifetime.
    static func manual() -> ReleasePolicy {
        return ReleasePolicy(type: .manual, param: 0)
    }
    
    /// Creates a new release policy configured to release the object after a specified number of uses.
    /// It's recommended to combine this type of policy with `expire()` to ensure the object is always released from memory.
    /// - Parameter count: Maximum number of object uses allowed.
    static func afterUse(_ count: Int) -> ReleasePolicy {
        return ReleasePolicy(type: .afterUse, param: count)
    }
    
    /// Creates a new release policy configured to release the object after a required time of inactivity.
    /// Inactivity means no interaction with the object in the defined time window.
    /// - Parameter timeIntervalMs: Time interval in milliseconds to keep the object alive from the last use attempt.
    static func keepAlive(_ timeIntervalMs: Int) -> ReleasePolicy {
        return ReleasePolicy(type: .keepAlive, param: timeIntervalMs)
    }
    
    /// Creates a new release policy configured to release the object after a required time.
    /// - Parameter timeIntervalMs: Time interval in milliseconds to keep the object alive.
    static func expire(_ timeIntervalMs: Int) -> ReleasePolicy {
        return ReleasePolicy(type: .expire, param: timeIntervalMs)
    }
    
    /// Compares two `ReleasePolicy` objects for equality.
    static func == (lhs: ReleasePolicy, rhs: ReleasePolicy) -> Bool {
        return lhs.value == rhs.value
    }
}
