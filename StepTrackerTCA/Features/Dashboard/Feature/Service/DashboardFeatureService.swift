//
//  DashboardFeatureService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 02/01/2025.
//

import Foundation

/// Protocol defining operations for managing the state related to the step data permission screen.
protocol DashboardFeatureService {
    
    /// A property indicating whether the permission screen has been shown to the user.
    ///
    /// - Returns: `true` if the permission screen has already been displayed, `false` otherwise.
    var hasSeenPermissionPriming: Bool { get }
    
    /// Marks the permission screen as shown.
    ///
    /// - Saves this information in a persistent source, such as UserDefaults.
    func markPermissionPrimingAsSeen()
    
    /// Fetches step data asynchronously.
    ///
    /// Shown in the step chart on the dashboard after successful retrieval of data.
    ///
    /// - Returns: An array of `HealthData` objects representing step metrics.
    /// - Throws: An error if data retrieval fails.
    func getStepsData() async throws -> [HealthData]
    
    /// Calculates the average step count from the given data.
    ///
    /// This utility method processes an array of `HealthData` and computes the average step count.
    /// It is used to provide quick insights to the user, such as the average number of steps over
    /// a given period.
    ///
    /// - Parameter data: An array of `HealthData` objects containing step metrics.
    /// - Returns: The average step count as a `Double`. Returns `0` if the input data is empty.
    func calculateAverageStepCount(from data: [HealthData]) -> Double
    
    /// Generates and saves mock HealthKit data for testing purposes.
    func getDummyData() async throws
    
}
