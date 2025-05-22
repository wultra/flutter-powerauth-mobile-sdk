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

import PowerAuth2
import PowerAuthCore
import Flutter

internal class PowerAuthObjectRegister {
    
    private let lock = Lock()
    private var register = [String: PowerAuthManagedObject](minimumCapacity: 16)
    private var scheduledCleanup = false
    private var cleanupPeriod = Constants.CLEANUP_PERIOD_DEFAULT
    
    private enum ObjectAction {
        case none
        case use
        case touch
        case remove
    }
    
    // MARK: - Native interface
    
    func add(object: Any, tag: String?, policies: [ReleasePolicy]) -> String {
        return lock.synchronized {
            let identifier = generateIdentifier()
            let managedObject = PowerAuthManagedObject(object: object, key: identifier, tag: tag, policies: policies)
            register[identifier] = managedObject
            scheduleClenaup()
            return identifier
        }
    }
    
    func add(object: Any, id: String, tag: String?, policies: [ReleasePolicy]) -> Bool {
        return add(id: id, tag: tag, policies: policies) { object }
    }
    
    func add(id: String, tag: String?, policies: [ReleasePolicy], objectFactory: () -> Any) -> Bool {
        
        return lock.synchronized {
            
            guard self.register[id] == nil else {
                return false
            }
            let managedObject = PowerAuthManagedObject(object: objectFactory(), key: id, tag: tag, policies: policies)
            register[id] = managedObject
            self.scheduleClenaup()
            return true
        }
    }
    
    func use<T>(id: String) -> T? {
        return lock.synchronized {
            return findManagedObject(id: id, action: .use)
        }
    }
    
    func useAny(id: String) -> Any? {
        return lock.synchronized {
            return findManagedObject(id: id, action: .use, validateType: false)
        }
    }
    
    func find<T>(id: String) -> T? {
        return lock.synchronized {
            return findManagedObject(id: id)
        }
    }
    
    func touch<T>(id: String) -> T? {
        return lock.synchronized {
            return findManagedObject(id: id, action: .touch)
        }
    }
    
    func touchAny(id: String) -> Any? {
        return lock.synchronized {
            return findManagedObject(id: id, action: .touch, validateType: false)
        }
    }
    
    func contains(id: String) -> Bool {
        return lock.synchronized {
            let obj: Any? = self.findManagedObject(id: id, validateType: false)
            return obj != nil
        }
    }
    
    func removeAll(tag: String) {
        lock.synchronized {
            self.findAndRemoveObjects { key, value in
                return tag == value.tag
            }
        }
    }
    
    func removeAll() {
        lock.synchronized {
            register.removeAll()
        }
    }
    
    func remove<T>(id: String) -> T? {
        return lock.synchronized {
            return self.findManagedObject(id: id, action: .remove)
        }
    }
    
    @discardableResult
    func removeAny(id: String) -> Any? {
        return lock.synchronized {
            return self.findManagedObject(id: id, action: .remove, validateType: false)
        }
    }
    
    func setCleanupPeriod(_ period: Int) {
        lock.synchronized {
            if period >= Constants.CLEANUP_PERIOD_MIN && period <= Constants.CLEANUP_PERIOD_MAX {
                self.cleanupPeriod = period
            } else {
                self.cleanupPeriod = Constants.CLEANUP_PERIOD_DEFAULT
            }
            // Kick the cleanup now, because we don't want to wait for the next
            // tick if period is shorter.
            self.doCleanup()
        }
    }
    
    /// Find object in the object register.
    /// - Parameters:
    ///   - objectId: Generated or application specific object register.
    ///   - expectedClass: Expected class to retrieve. If not provided, then the stored object can be anything.
    ///   - action: Additional operations that will be performed with the object
    /// - Returns: Object retrieved from the register or nil if no such object exist.
    private func findManagedObject<T>(id: String, action: ObjectAction = .none, validateType: Bool = true) -> T? {
        
        guard let managedObject = register[id] else {
            return nil
        }
        
        guard validateType == false || managedObject.object is T else {
            return nil
        }
        
        guard managedObject.isStillValid() else {
            return nil
        }
        
        switch action {
        case .none: break
        case .use: managedObject.setUsed()
        case .touch: managedObject.touch()
        case .remove: register.removeValue(forKey: id)
        }
        return managedObject.object as? T
    }
    
    /// Schedule an object cleanup job.
    private func scheduleClenaup() {
        guard scheduledCleanup == false && register.isEmpty == false else {
            return
        }
        scheduledCleanup = true
        // Wake-up after cleanup period seconds and do the cleanup.
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(cleanupPeriod)) {
            self.lock.synchronized {
                self.doCleanup()
            }
        }
    }
    
    /// Function remove expired or no loner valid objects from the register.
    private func doCleanup() {
        // Clear scheduled flag.
        scheduledCleanup = false
        // Remove all invalid objects
        findAndRemoveObjects { _, obj in
            obj.isStillValid() == false
        }
        // Schedule cleanup for the next round
        scheduleClenaup()
    }
    
    /// Function find and remove objects from the register. The provided block decide whether object
    /// needs to be removed.
    /// - Parameter block: Block that decide whether object needs to be removed.
    private func findAndRemoveObjects(block: (String, PowerAuthManagedObject) -> Bool) {
        // Find objects that should be removed
        var keysToRemove = [String]()
        for (key, value) in register {
            if block(key, value) {
                keysToRemove.append(key)
            }
        }
        for keyToRemove in keysToRemove {
            register.removeValue(forKey: keyToRemove)
        }
    }
    
    /// Generate a new object identifier.
    /// - Returns: New unique object identifier.
    private func generateIdentifier() -> String {
        while(true) {
            let identifier = Utils.getRandomString()
            if register[identifier] == nil {
                return identifier
            }
        }
    }
    
    func debugDumpObjectsWithTag(tag: String?) -> [Dictionary<String, Any?>] {
#if DEBUG
        return lock.synchronized {
            var content = [Dictionary<String, Any?>]()
            for (_, obj) in register {
                if let tag, (obj.tag == nil || obj.tag != tag ) {
                    continue
                }
                content.append(obj.debugDump())
            }
            return content
        }
#else
        return []
#endif
    }
    
#if DEBUG
//    - (NSString*) description
//    {
//        return [[self debugDumpObjectsWithTag:nil] description];
//    }
#endif // DEBUG
    
}

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
    
    static func getTimeInterval(value: Int?, defaultValue: Int) -> Int {
        #if DEBUG
        return min(value ?? defaultValue, defaultValue)
        #endif
        return defaultValue
    }
}

internal class PowerAuthManagedObject {
    
    let object: Any
    let key: String
    let tag: String?
    let createDate: Date
    
    var usageCount: Int = 0
    var lastUseDate: Date
    
    private lazy var managedByOwner = policies.contains(.manual())
    private let policies: [ReleasePolicy]
    
    init(object: Any, key: String, tag: String?, policies: [ReleasePolicy]) {
        let now = Date()
        self.object = object
        self.key = key
        self.tag = tag
        self.createDate = now
        self.lastUseDate = now
        self.policies = policies
    }
    
    func setUsed() {
        usageCount += 1
        lastUseDate = Date()
    }
    
    func touch() {
        lastUseDate = Date()
    }
    
    /// Evaluate whether time interval between now and reference date is greater or equal than time interval in release policy.
    /// - Parameters:
    ///   - refDate: Reference date.
    ///   - rp: Pointer to release policy structure.
    private func isExpired(refDate: Date, rp: ReleasePolicy) -> Bool {
        return -refDate.timeIntervalSinceNow * 1_000 >= Double(rp.getPolicyParam())
    }
    
    func isStillValid() -> Bool {
        // In case that object is manually managed, then don't iterate over the policies.
        guard managedByOwner == false else {
            return true
        }
        
        for policy in policies {
            switch policy.getPolicyType() {
            case .afterUse:
                if usageCount >= policy.getPolicyParam() {
                    return false
                }
                break;
            case .expire:
                if isExpired(refDate: createDate, rp: policy) {
                    return false
                }
            case .keepAlive:
                if isExpired(refDate: lastUseDate, rp: policy) {
                    return false
                }
            case .manual:
                // we cover this case earlier
                break
            }
        }
        return true
    }
    
    func debugDump() -> [String: Any?] {
#if DEBUG
        // Iterate over policies
        var printLastUseDate = false
        var printUsageCount = false
        var policies = [String]()
        if managedByOwner {
            policies.append("MANUAL")
        } else {
            for policy in self.policies {
                switch policy.getPolicyType() {
                case .afterUse:
                    policies.append("AFTER_USE(\(usageCount)/\(policy.getPolicyParam()))")
                    printUsageCount = true
                case .keepAlive:
                    policies.append("KEEP_ALIVE(\(policy.getPolicyParam()))")
                    printLastUseDate = true
                case .expire:
                    policies.append("EXPIRE(\(policy.getPolicyParam()))")
                case .manual:
                    break
                }
            }
        }
        return [
            "id": key,
            "class": "\(object.self)",
            "tag": tag,
            "createDate": createDate.timeIntervalSince1970,
            "lastUseDate": printLastUseDate ? lastUseDate.timeIntervalSince1970 : nil,
            "usageCount": printUsageCount ? usageCount : nil,
            "policies": policies,
            "isValid": isStillValid()
        ]
#else
        return [:]
#endif // DEBUG
    }
}

// Shortcut methods
extension PowerAuthObjectRegister {

    func usePassword(dict: FlutterMap?) throws -> PowerAuthCorePassword {
        return try getPasswordImpl(dict: dict, use: true)
    }
    
    func touchPassword(dict: FlutterMap?) throws -> PowerAuthCorePassword {
        return try getPasswordImpl(dict: dict, use: false)
    }
    
    func getPowerAuthSDK(id: String) -> PowerAuthSDK? {
        return find(id: id)
    }
    
    func requirePowerAuthSDK(id: String) throws -> PowerAuthSDK {
        guard let instance = getPowerAuthSDK(id: id) else {
            throw PluginException(.instanceNotConfigured, message: "PowerAuth instance not configured.")
        }
        return instance
    }
    
    func usePowerAuthSDK(id: String, _ result: @escaping FlutterResult, _ block: (PowerAuthSDK, @escaping WrapThrowBlock) throws -> Void) throws {
        let instance = try requirePowerAuthSDK(id: id)
        try block(instance) { tryBlock in
            Utils.wrapThrowBlock(result: result, tryBlock)
        }
    }
    
    // - Helpers
    
    private func getPasswordImpl(dict: FlutterMap?, use: Bool) throws -> PowerAuthCorePassword {
        
        guard let objectId = dict?["objectId"] as? String else {
            // Object identifier is not present in the object. This means that wrong object is passed to call,
            // or PowerAuthPassword dart object is not initialized yet.
            throw PluginException(.wrongParameter, message: "PowerAuthPassword is not initialized")
        }
        
        let password: PowerAuthCorePassword? = use ? self.use(id: objectId) : touch(id: objectId)
        guard let password else {
            throw PluginException(.invalidNativeObject, message: "PowerAuthPassword object is no longer valid")
        }
        return password
    }
}
