//
//  WeightGoalWidgetService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 16/01/2025.
//

import Foundation

/// A protocol for processing and retrieving weight data for `WeightGoalWidget`
protocol WeightGoalWidgetService {
    
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
    
    /// Calculates the average weight  from the given data.
    ///
    /// This utility method processes an array of `HealthData` and computes the average step count.
    /// It is used to provide quick insights to the user, such as the average number of steps over
    /// a given period.
    ///
    /// - Parameter data: An array of `HealthData` objects containing step metrics.
    /// - Returns: The average weight as a `Double`. Returns `0` if the input data is empty.
    func calculateWeightAverage(from data: [HealthData]) -> Double
    
}
