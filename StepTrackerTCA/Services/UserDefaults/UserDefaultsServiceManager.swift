//
//  UserDefaultsServiceManager.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 02/01/2025.
//

import Foundation

/// A service for managing data stored in UserDefaults.
/// Provides functionality to save, retrieve, and remove key-value pairs in UserDefaults.
/// 
final class UserDefaultsServiceManager: UserDefaultsService {
    
    // MARK: - Properties
    
    private let userDefaults: UserDefaults
    
    // MARK: - Lifecycle
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - UserDefaultsService Methods
    
    public func set<T>(_ value: T?, forKey key: DefaultsKey) {
        userDefaults.set(value, forKey: key.rawValue)
    }
    
    public func get<T>(objectForKey key: DefaultsKey) -> T? {
        userDefaults.object(forKey: key.rawValue) as? T
    }
    
    public func remove(for key: DefaultsKey) {
        userDefaults.removeObject(forKey: key.rawValue)
    }
    
}
