//
//  HealthKitManager.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 28/12/2024.
//

import Foundation
import HealthKit

/// A protocol defining the required properties for managing HealthKit data.
protocol HealthKitManager {
    
    /// The HealthKit store used to access and manage HealthKit data.
    ///
    /// `HKHealthStore` is responsible for interacting with the HealthKit framework.
    var store: HKHealthStore { get }
    
    /// A set of sample types that the manager requests write access to.
    var shareTypes: Set<HKSampleType> { get }
    
    /// A set of object types that the manager requests read access to.
    var readTypes: Set<HKObjectType> { get }
    
    /// Requests authorization to access HealthKit data.
     ///
     /// This method triggers the HealthKit authorization flow, asking the user
     /// for permission to access the specified `shareTypes` and `readTypes`.
     ///
     /// - Returns: A result of type `Result<Bool, Error>` indicating success or an authorization error.
    func requestAuthorization() async -> Result<Bool, Error>
    
    
    /// Adds simulated HealthKit data for testing purposes.
    ///
    /// This method generates mock step count and body mass samples for the last 28 days
    /// and saves them to the HealthKit store. Each day's data includes random values for
    /// step count (ranging from 4,000 to 20,000) and body mass (incrementally increasing
    /// within a specific range).
    ///
    /// - Important: Use this function only in debug or testing environments, as it populates
    /// HealthKit with dummy data.
    ///
    /// - Throws: An error if saving the data to the HealthKit store fails.
    ///
    /// - Precondition: Ensure that the app has proper authorization to write the required
    /// HealthKit data types (`HKQuantityType.stepCount` and `HKQuantityType.bodyMass`).
    func addSimulatorData() async throws
    
}
