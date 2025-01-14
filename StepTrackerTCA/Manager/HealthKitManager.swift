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
    
    /// Calculates the average value of health data for each weekday.
    ///
    /// The function groups health data by weekdays, computes the average value
    /// for each day, and returns the results as an array.
    ///
    /// - Parameter healthData: An array of `HealthData` objects, each containing a date and a value (e.g., step count).
    /// - Returns: An array of `WeekdayChartData` objects, where each entry represents the average value
    ///            of the data for a specific weekday.
    func averageWeekdayCount(for healthData: [HealthData]) -> [WeekdayChartData]
    
    /// Calculates the minimum value from the provided health data.
    ///
    /// This method iterates through an array of `HealthData` to determine the lowest value.
    /// For instance, it can be used to find the minimum recorded weight over a set of days.
    ///
    /// - Parameter healthData: An array of `HealthData` objects, where each object represents
    ///   health-related data for a specific day, including a date and a value (e.g., weight).
    ///
    /// - Returns: The smallest value from the array of health data. If the array is empty,
    ///   the function returns `0.0`.
    func calculateMinValue(from healthData: [HealthData]) -> Double 
    
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
