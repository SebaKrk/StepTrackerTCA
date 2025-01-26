//
//  UserDefaultsService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 02/01/2025.
//

import Foundation

protocol UserDefaultsService {
    
    /// Saves a value to UserDefaults
    ///
    /// - Parameter value: Simple types like `String`, `Bool`, `Int`, etc.
    /// - Parameter key: Key under which the value is stored.
    func set<T>(_ value: T?, forKey key: DefaultsKey)
    
    /// Retrieves a value from UserDefaults
    ///
    /// - Parameter key: Key under which the value is stored.
    /// - Returns: The value stored under the given key, or `nil` if it does not exist.
    func get<T>(objectForKey key: DefaultsKey) -> T?
    
    /// Deletes a value for a key in UserDefaults
    ///
    /// - Parameter key: Key for the value to remove.
    func remove(for key: DefaultsKey)
    
}
