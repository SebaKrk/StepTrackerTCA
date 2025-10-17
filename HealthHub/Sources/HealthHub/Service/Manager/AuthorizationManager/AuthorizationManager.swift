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
    
    /// Retrieves the current authorization statuses for all sample types.
    ///
    /// This method returns a dictionary mapping each `HKSampleType` to its corresponding `HKAuthorizationStatus`.
    /// Use this to check which HealthKit data types have been authorized, denied, or not determined.
    ///
    /// - Returns: A dictionary where keys are `HKSampleType` instances and values are their `HKAuthorizationStatus`.
    //func authorizationStatuses() -> [HKSampleType: HKAuthorizationStatus]
    func authorizationStatuses() -> [String: Bool]
    
        
    /// Checks if the app is authorized to share all required HealthKit data types.
    ///
    /// - Returns: `true` if the app has authorization for all required share types; otherwise, `false`.
    ///
    /// Use this method to verify that the app has the necessary permissions to write data to HealthKit before attempting to save any samples.
    func isAuthorizedForAllRequiredShareTypes() -> Bool
}
