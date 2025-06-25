//
//  AuthorizationManager.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 31/05/2025.
//

import Foundation
import HealthKit

/// A protocol that defines the interface for managing HealthKit authorization.
public protocol AuthorizationManager: Sendable {
    
    /// The HealthKit store used to access and manage HealthKit data.
    ///
    /// `HKHealthStore` is responsible for interacting with the HealthKit framework.
    var healthStore: HKHealthStore { get }
    
    /// Requests authorization to access HealthKit data.
    ///
    /// This method triggers the HealthKit authorization flow, asking the user
    /// for permission to access the specified `shareTypes` and `readTypes`.
    ///
    /// - Returns: A result of type `Result<Bool, Error>` indicating success or an authorization error.
    func requestAuthorization() async -> Result<Bool, Error>
    
}
