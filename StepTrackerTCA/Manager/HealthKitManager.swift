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
    
    /// Fetches health data for a specified quantity type within a given date range.
    ///
    /// This method queries HealthKit for cumulative health data (e.g., step count, distance, calories)
    /// for the specified `HKQuantityTypeIdentifier` over a range of days. The result is an array of
    /// `HealthData` containing date-value pairs.
    ///
    /// - Parameters:
    ///   - quantityType: The `HKQuantityTypeIdentifier` representing the type of health data to fetch
    ///                   (e.g., `.stepCount`, `.distanceWalkingRunning`, `.activeEnergyBurned`).
    ///   - days: The number of days for which data should be fetched, counting backward from today.
    ///           For example, if `days` is 7, the query will include data from 7 days ago up to today.
    ///   - unit: The `HKUnit` to use for the fetched data. For instance, `.count()` for step count,
    ///           `.kilocalorie()` for energy, or `.meter()` for distance.
    ///
    /// - Returns: An array of `HealthData`, where each entry represents aggregated health data for
    ///            a specific day within the date range. Each `HealthData` includes a date and the
    ///            corresponding value for that date.
    ///
    /// - Throws: An error if the HealthKit query fails, such as lack of permissions or unsupported types.
    func fetchHealthData(for quantityType: HKQuantityTypeIdentifier, days: Int, unit: HKUnit, options: HKStatisticsOptions) async throws -> [HealthData]
    
    /// Adds health data to the HealthKit store for a specific date, value, and type.
    ///
    /// This method saves a single sample of health data, such as step count or body mass,
    /// to the HealthKit store. The data is defined by the specified quantity type, value, and unit.
    ///
    /// - Parameters:
    ///   - date: The date and time associated with the health data.
    ///           This is both the start and end time for the sample.
    ///   - value: The numeric value of the health data (e.g., 5000 for step count or 70.5 for body mass).
    ///   - type: The `HKQuantityTypeIdentifier` representing the type of data to be saved,
    ///           such as `.stepCount` or `.bodyMass`.
    ///   - unit: The `HKUnit` used to represent the value, such as `.count()` for step count
    ///           or `.kilogram()` for body mass.
    ///
    /// - Throws: An error if the HealthKit sample cannot be saved, such as due to lack of
    ///           permissions or invalid parameters.
    ///
    /// - Precondition: Ensure that the app has proper authorization to write the specified
    ///                 `HKQuantityTypeIdentifier` to HealthKit using the `requestAuthorization` method.
    ///
    func addHealthData(for date: Date, value: Double, type: HKQuantityTypeIdentifier, unit: HKUnit) async throws
    
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
