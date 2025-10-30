//
//  ActivityRingManager.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 06/06/2025.
//

import SharedModels
import Foundation

/// A protocol that defines the interface for managing and retrieving activity ring data.
/// Implementers of this protocol are responsible for fetching activity summaries,
/// typically representing the user's physical activity for the current day.
public protocol ActivityRingManager: Sendable {
    
    /// Fetches the activity summary for the current day.
    ///
    /// - Returns: An `ActivityRingData` object containing the user's activity information for today.
    /// - Throws: An error if the data retrieval fails or is unavailable.
    func fetchTodaySummary() async throws -> ActivityRingData
    
    /// Fetches hourly activity data for the current day.
    ///
    /// - Returns: An array of `HourlyActivityData` objects, one for each hour of the day (0-23).
    /// - Throws: An error if the data retrieval fails or is unavailable.
    func fetchTodayHourlyData() async throws -> [HourlyActivityData]
}
