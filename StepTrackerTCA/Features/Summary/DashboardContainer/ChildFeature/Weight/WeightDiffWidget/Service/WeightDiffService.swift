//
//  WeightBarWidgetService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 17/01/2025.
//

import Foundation

/// Protocol defining operations for managing the state related to the weight data permission screen.
protocol WeightDiffService {
    
    /// Retrieves the health metric that corresponds to the selected date.
    ///
    /// This method searches through an array of `WeekdayChartData` objects to find a record
    /// that matches the provided date. If no match is found, it returns `nil`.
    ///
    /// - Parameters:
    ///   - weekdayChartData: An array of `WeekdayChartData` objects representing health metrics, each associated with a specific date.
    ///   - rawSelectedDate: An optional `Date` object representing the date for which to fetch the corresponding health metric.
    /// - Returns:
    ///   The `WeekdayChartData` object matching the selected date, or `nil` if no match is found or the `rawSelectedDate` is `nil`.
    func selectedHealthMetric(from weekdayChartData: [WeekdayChartData], with rawSelectedDate: Date?) -> WeekdayChartData?
    
    /// Calculates the average daily weight differences based on the provided array of health data.
    ///
    /// This function processes the given health data, which includes weight measurements associated with specific dates,
    /// to compute daily weight differences. It aggregates these differences into a collection of `WeekdayChartData` objects.
    ///
    /// - Parameter weights: An array of `HealthData` objects, each containing weight information and associated metadata.
    /// - Returns:
    ///   An array of `WeekdayChartData` objects, where each object represents the average weight difference for a specific day of the week.
    func averageDailyWeightDiffs(for weights: [HealthData]) -> [WeekdayChartData]
}
