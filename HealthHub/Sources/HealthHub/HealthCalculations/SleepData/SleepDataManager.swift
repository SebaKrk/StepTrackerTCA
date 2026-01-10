//
//  SleepDataManager.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 29/09/2025.
//

import Foundation
import SharedModels

/// A protocol defining methods for retrieving sleep data from HealthKit.
///
/// `SleepDataManager` provides a standardized interface for accessing sleep-related
/// health information stored in Apple's HealthKit framework. It focuses on retrieving
/// sleep duration data needed for training readiness calculations.
///
/// ## Overview
/// The protocol uses pragmatic time windows rather than precise sleep session boundaries:
/// - Last night's sleep: Data from evening (8 PM yesterday) to morning (10 AM today)
/// - Historical averages: Same windows applied to previous nights
///
/// This approach ensures reliable data retrieval even when Apple Watch sleep tracking
/// has gaps or inconsistencies in session boundaries.
///
/// ## Usage
/// ```swift
/// let sleepManager = DefaultSleepDataManager()
///
/// // Get last night's total sleep
/// if let lastNight = try await sleepManager.getLastNightSleep() {
///     print("Slept \(lastNight.value) hours last night")
/// }
///
/// // Get 7-day average
/// if let average = try await sleepManager.getAverageSleepFromLastNights(nights: 7) {
///     print("Average sleep: \(average.value) hours")
/// }
/// ```
public protocol SleepDataManager: Sendable {
    
    /// Retrieves total sleep duration from last night.
    ///
    /// Fetches sleep data from the pragmatic window spanning yesterday evening (8 PM)
    /// to this morning (10 AM). This captures the primary sleep session regardless of
    /// exact start/end times or brief awakenings.
    ///
    /// The method sums all "asleep" periods within this window, excluding:
    /// - Time spent awake in bed
    /// - Time spent in bed but not asleep
    ///
    /// - Returns: A `HealthKitData` object containing sleep duration in hours, or `nil` if unavailable
    /// - Throws: HealthKit errors if data access fails
    ///
    /// ## Time Window
    /// - Start: 8:00 PM yesterday
    /// - End: 10:00 AM today
    /// - Captures: Core sleep, deep sleep, REM sleep
    /// - Excludes: Awake time, in-bed-but-not-asleep time
    func getLastNightSleep() async throws -> HealthKitData?
    
    /// Retrieves average sleep duration from specified number of nights.
    ///
    /// Calculates the mean sleep duration by fetching data from multiple nights using
    /// the same pragmatic time window (8 PM → 10 AM) for each night. Only nights with
    /// available data are included in the average calculation.
    ///
    /// - Parameter nights: Number of nights to average (default: 7)
    /// - Returns: A `HealthKitData` object containing average sleep in hours, or `nil` if unavailable
    /// - Throws: HealthKit errors if data access fails
    ///
    /// ## Calculation Details
    /// - Each night uses 8 PM → 10 AM window
    /// - Average includes only nights with data
    /// - Result timestamp is current date/time
    ///
    /// ## Example
    /// ```swift
    /// // Get 7-night average for baseline comparison
    /// let baseline = try await getAverageSleepFromLastNights(nights: 7)
    /// ```
    func getAverageSleepFromLastNights(nights: Int) async throws -> HealthKitData?
    
    /// Retrieves sleep duration data for each of the last N nights as individual data points.
    ///
    /// Fetches sleep data for each night separately, returning an array where each element
    /// represents one night's sleep duration. This is useful for displaying historical trends,
    /// charts, or day-by-day comparisons.
    ///
    /// - Parameter nights: Number of nights to retrieve (e.g., 7 for last week, 30 for last month)
    /// - Returns: Array of `HealthKitData?` where:
    ///   - Each element represents one night's sleep duration in hours
    ///   - `nil` elements indicate nights with no sleep data available
    ///   - Array is ordered chronologically (oldest first, most recent last)
    /// - Throws: HealthKit errors if data access fails
    ///
    /// ## Implementation Details
    /// - Uses the same 8 PM → 10 AM window for each night
    /// - Captures: Core sleep, deep sleep, REM sleep
    /// - Excludes: Awake time, in-bed-but-not-asleep time
    /// - Handles duplicate samples and overlapping intervals automatically
    /// - Each night's data point uses the window end time (10 AM) as its timestamp
    ///
    /// ## Example Usage
    /// ```swift
    /// let sleepManager = DefaultSleepDataManager()
    ///
    /// // Get last 7 nights for a weekly chart
    /// let weekHistory = try await sleepManager.getSleepHistory(nights: 7)
    /// for (index, nightData) in weekHistory.enumerated() {
    ///     if let data = nightData {
    ///         print("Night \(index + 1): \(data.value) hours")
    ///     } else {
    ///         print("Night \(index + 1): No data")
    ///     }
    /// }
    ///
    /// // Get last 30 nights for monthly trend analysis
    /// let monthHistory = try await sleepManager.getSleepHistory(nights: 30)
    /// let validNights = monthHistory.compactMap { $0 }
    /// let average = validNights.reduce(0.0) { $0 + $1.value } / Double(validNights.count)
    /// ```
    ///
    /// ## Common Use Cases
    /// - **Chart Visualization**: Plot sleep duration over time in Swift Charts
    /// - **Trend Analysis**: Calculate rolling averages or identify sleep patterns
    /// - **Comparison**: Compare current week vs. previous week
    /// - **Data Validation**: Check for consistency or gaps in sleep tracking
    ///
    /// ## Notes
    /// - Returned array length always equals the requested `nights` parameter
    /// - Missing data (nil values) can occur if:
    ///   - User didn't wear Apple Watch during sleep
    ///   - Sleep tracking was disabled
    ///   - Data hasn't synced yet
    /// - Consider using `compactMap` when you need only valid sleep entries
    func getSleepHistory(nights: Int) async throws -> [HealthKitData?]
}
