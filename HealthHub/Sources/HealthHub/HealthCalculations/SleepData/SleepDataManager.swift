//
//  SleepDataManager.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 29/09/2025.
//

import Foundation
import SharedModels

/// Protocol defining methods for retrieving sleep data from HealthKit.
///
/// `SleepDataManager` provides a standardized interface for accessing sleep analysis
/// data including sleep duration, sleep stages, and sleep quality metrics.
///
/// ## Overview
/// Sleep data is crucial for assessing recovery and training readiness. This protocol
/// provides methods to fetch both recent sleep sessions and historical averages.
///
/// ## Usage
/// ```swift
/// let sleepManager = DefaultSleepDataManager()
/// 
/// // Get last night's sleep
/// if let sleep = try await sleepManager.getSleepDuration(days: 1) {
///     print("Slept \(sleep.value) hours")
/// }
/// ```
public protocol SleepDataManager: Sendable {
    
    /// Retrieves total sleep duration from specified time period.
    ///
    /// Fetches sleep analysis data from HealthKit and calculates total sleep time.
    /// This includes all sleep stages (deep, REM, core, etc.) but excludes awake time.
    ///
    /// - Parameter days: Number of days to look back (default: 1 for last night)
    /// - Returns: A `HealthKitData` object containing sleep duration in hours,
    ///           or `nil` if no sleep data is available
    /// - Throws: HealthKit errors if data access fails
    func getSleepDuration(days: Int) async throws -> HealthKitData?
}
