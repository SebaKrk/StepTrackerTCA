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
}
