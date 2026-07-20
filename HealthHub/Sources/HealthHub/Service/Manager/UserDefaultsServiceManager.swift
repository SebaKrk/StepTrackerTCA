//
//  UserDefaultsServiceManager.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 24/01/2026.
//

import Foundation

/// A generic, thread-safe manager for UserDefaults operations.
/// Supports both standard UserDefaults and App Group shared containers.
public final class UserDefaultsServiceManager: @unchecked Sendable {
    
    // MARK: - Properties
    
    private let userDefaults: UserDefaults?
    private let suiteName: String?
    
    // MARK: - Lifecycle
    
    /// Initializes with standard UserDefaults.
    public init() {
        self.suiteName = nil
        self.userDefaults = .standard
    }
    
    /// Initializes with App Group shared container.
    /// - Parameter suiteName: App Group identifier (e.g., "group.com.ss.lf.WorkoutMirrorLive")
    public init(suiteName: String) {
        self.suiteName = suiteName
        self.userDefaults = UserDefaults(suiteName: suiteName)
    }
    
    // MARK: - Generic Methods
    
    /// Saves an Encodable object to UserDefaults.
    public func save<T: Encodable>(_ object: T, forKey key: String) {
        guard let userDefaults = userDefaults else {
            print("❌ UserDefaultsServiceManager: UserDefaults is nil for suite: \(suiteName ?? "standard")")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(object)
            userDefaults.set(data, forKey: key)
        } catch {
            print("❌ UserDefaultsServiceManager: Failed to encode \(key): \(error)")
        }
    }
    
    /// Loads a Decodable object from UserDefaults.
    public func load<T: Decodable>(forKey key: String) -> T? {
        guard let userDefaults = userDefaults,
              let data = userDefaults.data(forKey: key) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("❌ UserDefaultsServiceManager: Failed to decode \(key): \(error)")
            return nil
        }
    }
    
    /// Removes value for key.
    public func remove(forKey key: String) {
        userDefaults?.removeObject(forKey: key)
    }
    
    /// Sets a simple value (String, Int, Bool, etc.)
    public func set(_ value: Any?, forKey key: String) {
        userDefaults?.set(value, forKey: key)
    }
    
    /// Gets a simple value.
    public func get<T>(forKey key: String) -> T? {
        userDefaults?.object(forKey: key) as? T
    }
}

// MARK: - Convenience Factory

public extension UserDefaultsServiceManager {
    /// Shared instance for App Group (Widget + Main App communication)
    static let appGroup = UserDefaultsServiceManager(suiteName: "group.com.ss.lf.WorkoutMirrorLive")
    
    /// Standard UserDefaults instance
    static let standard = UserDefaultsServiceManager()
}
