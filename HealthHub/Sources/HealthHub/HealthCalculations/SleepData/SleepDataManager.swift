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
/// Callers pass the windows they want read. Readiness derives those windows from
/// an actual sleep session, so the protocol must not assume fixed clock hours of
/// its own — that assumption is what made the score depend on the time of day.
///
/// ## Usage
/// ```swift
/// let sleepManager = DefaultSleepDataManager()
///
/// // Raw intervals, to reconstruct the night
/// let intervals = try await sleepManager.getSleepIntervals(in: searchStart...now)
///
/// // Baseline across the preceding nights
/// if let average = try await sleepManager.getAverageSleepHours(in: nightWindows) {
///     print("Average sleep: \(average.value) hours")
/// }
/// ```
public protocol SleepDataManager: Sendable {
    
    /// Retrieves raw asleep intervals within a window.
    ///
    /// Returns the intervals themselves rather than a total, so the caller can
    /// reconstruct where one night ends and the next begins. Awake and in-bed
    /// periods are excluded; duplicates from device sync are not, and are the
    /// caller's to merge.
    ///
    /// - Parameter window: Range to read intervals from
    /// - Returns: Asleep intervals overlapping the window, in no guaranteed order
    /// - Throws: HealthKit errors if data access fails
    func getSleepIntervals(in window: ClosedRange<Date>) async throws -> [SleepSessionBuilder.Interval]

    /// Retrieves average sleep duration across the given night windows.
    ///
    /// Only nights with data contribute to the average, so a missing night lowers
    /// the sample count rather than the mean.
    ///
    /// - Parameter windows: One range per night to average over
    /// - Returns: A `HealthKitData` object containing average sleep in hours, or `nil` if unavailable
    /// - Throws: HealthKit errors if data access fails
    ///
    /// ## Example
    /// ```swift
    /// let windows = TrainingReadinessTimeWindows.previousNights(count: 7, before: day)
    /// let baseline = try await getAverageSleepHours(in: windows)
    /// ```
    func getAverageSleepHours(in windows: [ClosedRange<Date>]) async throws -> HealthKitData?
    
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
