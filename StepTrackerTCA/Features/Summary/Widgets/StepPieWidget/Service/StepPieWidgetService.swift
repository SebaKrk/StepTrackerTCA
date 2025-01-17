//
//  StepPieWidgetService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 17/01/2025.
//

import Foundation

protocol StepPieWidgetService {
 
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
    
    /// Calculates the total number of steps from an array of health data.
    /// - Parameter data: An array of `HealthData` objects containing step counts and their associated dates.
    /// - Returns: The total number of steps as a `Double`.
    func calculateTotalSteps(from data: [HealthData]) -> Double
    
    /// Retrieves the weekday chart data corresponding to the selected chart value.
    ///
    /// This method maps a raw chart value (e.g., step count) to the appropriate weekday data,
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
    
}
