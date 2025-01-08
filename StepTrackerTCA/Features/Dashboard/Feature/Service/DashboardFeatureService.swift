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
    
    /// Calculates the total number of steps from an array of health data.
    /// - Parameter data: An array of `HealthData` objects containing step counts and their associated dates.
    /// - Returns: The total number of steps as a `Double`.
    func calculateTotalSteps(from data: [HealthData]) -> Double
    
    /// Retrieves the health metric that corresponds to the selected date.
    ///
    /// This method searches through an array of `HealthData` objects to find a record
    /// that matches the provided date. If no match is found, it returns `nil`.
    ///
    /// - Parameters:
    ///   - healthData: An array of `HealthData` objects representing health metrics, each associated with a specific date.
    ///   - rawSelectedDate: An optional `Date` object representing the date for which to fetch the corresponding health metric.
    /// - Returns:
    ///   The `HealthData` object matching the selected date, or `nil` if no match is found or the `rawSelectedDate` is `nil`.
    func selectedHealthMetric(from healthData: [HealthData], with rawSelectedDate: Date?) -> HealthData?
    
    /// Retrieves the health metric that corresponds to the selected date.
    ///
    /// This method searches through an array of `HealthData` objects to find a record
    /// that matches the provided date. If no match is found, it returns `nil`.
    ///
    /// - Parameters:
    ///   - healthData: An array of `HealthData` objects representing health metrics, each associated with a specific date.
    ///   - rawSelectedDate: An optional `Date` object representing the date for which to fetch the corresponding health metric.
    /// - Returns:
    ///   The `HealthData` object matching the selected date, or `nil` if no match is found or the `rawSelectedDate` is `nil`.
    func calculateAverageHealthDataPerWeekday( _ healthData: [HealthData]) -> [WeekdayChartData]
    
    /// Retrieves the weekday chart data corresponding to the selected chart value.
    ///
    /// This method maps a raw chart value (e.g., step count) to the appropriate weekday data,
    /// typically for display or further processing.
    ///
    /// - Parameters:
    ///   - healthData: An array of `WeekdayChartData` objects representing metrics aggregated by weekdays.
    ///   - rawSelectedChartValue: An optional `Double` representing the raw value selected on the chart.
    /// - Returns:
    ///   The `WeekdayChartData` object matching the selected chart value, or `nil` if no match is found.
    func selectedWeekday(from healthData: [WeekdayChartData], with rawSelectedChartValue: Double?) -> WeekdayChartData?
    
    /// Generates and saves mock HealthKit data for testing purposes.
    func getDummyData() async throws
    
}
