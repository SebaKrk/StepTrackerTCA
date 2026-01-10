//
//  PersonalDataManager.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 22/09/2025.
//

import Foundation
import SharedModels

/// A protocol defining methods for retrieving personal health data from HealthKit.
///
/// `PersonalDataManager` provides a standardized interface for accessing various types
/// of personal health information stored in Apple's HealthKit framework. This includes
/// both characteristic data (unchanging personal attributes) and quantity measurements
/// (physical metrics that can vary over time).
///
/// ## Overview
/// The protocol separates personal health data into two categories:
/// - **Characteristics**: Unchanging personal attributes like age and biological sex
/// - **Measurements**: Physical metrics that can change over time, such as height, weight, and heart rate
///
/// ## Usage
/// Implement this protocol to create a service that can fetch personal health data
/// for user profile management, fitness calculations, or health tracking features.
///
/// ```swift
/// let personalData = DefaultPersonalDataManager()
///
/// // Get user's age for HR max calculations
/// if let age = try await personalData.getAge() {
///     let maxHR = 220 - age
/// }
///
/// // Get latest weight measurement
/// if let weightData = try await personalData.getWeight() {
///     print("Current weight: \(weightData.value) kg")
/// }
/// ```
public protocol PersonalDataManager: Sendable {
    
    // MARK: - Characteristics
    
    /// Retrieves the user's age calculated from their date of birth.
    ///
    /// This method fetches the date of birth from HealthKit characteristics and
    /// calculates the current age in years.
    ///
    /// - Returns: The user's age in years, or `nil` if date of birth is not available
    /// - Throws: HealthKit errors if data access fails
    func getAge() async throws -> Int?
    
    /// Retrieves the user's biological sex from HealthKit.
    ///
    /// This method fetches the biological sex characteristic and returns it as a
    /// `BiologicalSex` enum value representing the user's biological sex.
    ///
    /// - Returns: A `BiologicalSex` enum value (.male, .female, .notSet, .unknown),
    ///           or `nil` if data is not available or access is denied
    /// - Throws: HealthKit errors if data access fails or permission is not granted
    ///
    /// ## Available Values:
    /// - `.male` - Male biological sex
    /// - `.female` - Female biological sex
    /// - `.notSet` - User hasn't set biological sex in Health app
    /// - `.unknown` - Biological sex is unknown or unspecified
    func getBiologicalSex() async throws -> BiologicalSex?
    
    // MARK: - Body Metrics
    
    /// Retrieves the user's most recent height measurement.
    ///
    /// This method fetches the latest height measurement from HealthKit quantity samples.
    /// The value is returned in centimeters for consistent UI display.
    ///
    /// - Returns: A `HealthKitData` object containing the height measurement in centimeters,
    ///           or `nil` if no height data is available
    /// - Throws: HealthKit errors if data access fails
    func getHeight() async throws -> HealthKitData?
    
    /// Retrieves weight for a specific date, with fallback to nearest previous measurement.
    ///
    /// Used for calculating metrics (like METs) for historical workouts where
    /// the weight from the workout date should be used, not current weight.
    ///
    /// Priority:
    /// 1. Weight from the same day as the date
    /// 2. Most recent weight BEFORE that date
    /// 3. nil if no weight data exists
    ///
    /// - Parameter date: The target date (typically workout.startDate)
    /// - Returns: A `HealthKitData` object containing weight in kilograms,
    ///           or `nil` if no weight data is available
    /// - Throws: HealthKit errors if data access fails
    func getWeight(for date: Date) async throws -> HealthKitData?
    
    /// Retrieves the user's average weight measurement from specified time period.
    ///
    /// This method fetches body mass measurements from HealthKit and calculates the average
    /// over the specified number of days. Defaults to the most recent day if no parameter provided.
    ///
    /// - Parameter days: Number of days to look back for averaging (default: 30)
    /// - Returns: A `HealthKitData` object containing the weight measurement in kilograms,
    ///           or `nil` if no weight data is available
    /// - Throws: HealthKit errors if data access fails
    func getWeight(days: Int) async throws -> HealthKitData?
    
    // MARK: - General Heart Rate
    
    /// Retrieves resting heart rate for a specific date, with fallback to nearest previous measurement.
    ///
    /// Used for calculating hrTSS for historical workouts where
    /// the resting HR from the workout date should be used.
    ///
    /// Priority:
    /// 1. Resting HR from the same day (morning window 00:00 - 11:00)
    /// 2. Most recent resting HR BEFORE that date
    /// 3. nil if no data exists
    ///
    /// - Parameter date: The target date (typically workout.startDate)
    /// - Returns: A `HealthKitData` object containing resting HR in bpm,
    ///           or `nil` if no data is available
    /// - Throws: HealthKit errors if data access fails
    func getRestingHeartRate(for date: Date) async throws -> HealthKitData?
    
    /// Retrieves the user's average resting heart rate from specified time period.
    ///
    /// This method fetches resting heart rate measurements from HealthKit and calculates
    /// the average over the specified number of days. Typically measured automatically
    /// by Apple Watch during periods of rest.
    ///
    /// - Parameter days: Number of days to look back for averaging (default: 7)
    /// - Returns: A `HealthKitData` object containing the resting heart rate in beats per minute,
    ///           or `nil` if no resting heart rate data is available
    /// - Throws: HealthKit errors if data access fails
    func getRestingHeartRate(days: Int) async throws -> HealthKitData?
    
    /// Retrieves the user's average heart rate variability from specified time period.
    ///
    /// HRV measures the variation in time between heartbeats, indicating autonomic nervous
    /// system balance. Higher HRV generally suggests better recovery and readiness.
    ///
    /// - Parameter days: Number of days to look back for averaging (default: 7)
    /// - Returns: A `HealthKitData` object containing HRV in milliseconds,
    ///           or `nil` if no HRV data is available
    /// - Throws: HealthKit errors if data access fails
    func getHeartRateVariability(days: Int) async throws -> HealthKitData?
    
    // MARK: - General Activity
    
    /// Retrieves the user's active energy burned from specified time period.
    ///
    /// This method fetches active energy expenditure data from HealthKit, which represents
    /// calories burned through physical activity (excluding basal metabolic rate).
    /// Used to assess training load and its impact on recovery.
    ///
    /// - Parameter days: Number of days to look back for calculation (default: 1)
    /// - Returns: A `HealthKitData` object containing active energy in kilocalories,
    ///           or `nil` if no activity data is available
    /// - Throws: HealthKit errors if data access fails
    func getActiveEnergyBurned(days: Int) async throws -> HealthKitData?
    
    // MARK: - Training Readiness Specific
    
    /// Retrieves this morning's resting heart rate measurement.
    ///
    /// Fetches RHR from the extended morning window (midnight - 11 AM today) to capture
    /// measurements taken during sleep and early morning. Apple Watch typically records
    /// RHR during sleep periods.
    ///
    /// - Returns: A `HealthKitData` object containing RHR in bpm, or `nil` if unavailable
    /// - Throws: HealthKit errors if data access fails
    func getThisMorningRestingHeartRate() async throws -> HealthKitData?
    
    /// Retrieves average morning resting heart rate from specified number of days.
    ///
    /// Fetches RHR measurements from the extended morning window (midnight - 11 AM) for
    /// each of the specified days and calculates their average.
    ///
    /// - Parameter days: Number of days to average (default: 7)
    /// - Returns: A `HealthKitData` object containing average morning RHR in bpm, or `nil` if unavailable
    /// - Throws: HealthKit errors if data access fails
    func getAverageMorningRestingHeartRate(days: Int) async throws -> HealthKitData?
    
    /// Retrieves last night's HRV measurement.
    ///
    /// Fetches HRV from last night's sleep window (8 PM yesterday - 10 AM today).
    ///
    /// - Returns: A `HealthKitData` object containing HRV in milliseconds, or `nil` if unavailable
    /// - Throws: HealthKit errors if data access fails
    func getLastNightHRV() async throws -> HealthKitData?
    
    /// Retrieves average nightly HRV from specified number of nights.
    ///
    /// - Parameter nights: Number of nights to average (default: 7)
    /// - Returns: A `HealthKitData` object containing average HRV in milliseconds, or `nil` if unavailable
    /// - Throws: HealthKit errors if data access fails
    func getAverageNightlyHRV(nights: Int) async throws -> HealthKitData?
    
    /// Retrieves yesterday's total active energy burned.
    ///
    /// Fetches activity from full previous day (00:00 - 23:59 yesterday).
    ///
    /// - Returns: A `HealthKitData` object containing active energy in kcal, or `nil` if unavailable
    /// - Throws: HealthKit errors if data access fails
    func getYesterdayActiveEnergy() async throws -> HealthKitData?
    
    /// Retrieves average daily active energy from specified number of days.
    ///
    /// - Parameter days: Number of days to average (default: 7)
    /// - Returns: A `HealthKitData` object containing average daily energy in kcal, or `nil` if unavailable
    /// - Throws: HealthKit errors if data access fails
    func getAverageDailyActiveEnergy(days: Int) async throws -> HealthKitData?
    
    /// DEBUG: Lists all RHR measurements from the last 7 days
    func debugListAllRHR() async throws
    
    // MARK: - Historical Data Per-Day
    
    /// Retrieves resting heart rate data for each of the last N days as individual data points.
    ///
    /// Fetches RHR data for each day separately, returning an array where each element
    /// represents one day's morning resting heart rate measurement. This is useful for
    /// displaying historical trends, charts, or day-by-day comparisons of cardiovascular recovery.
    ///
    /// - Parameter days: Number of days to retrieve (e.g., 7 for last week, 30 for last month)
    /// - Returns: Array of `HealthKitData?` where:
    ///   - Each element represents one day's RHR in beats per minute (bpm)
    ///   - `nil` elements indicate days with no RHR data available
    ///   - Array is ordered chronologically (oldest first, most recent last)
    /// - Throws: HealthKit errors if data access fails
    ///
    /// ## Implementation Details
    /// - Uses morning window (00:00 - 11:00) for each day to capture overnight measurements
    /// - Fallback: If no morning data exists, uses most recent RHR from before that day
    /// - Each data point uses the measurement's actual timestamp
    /// - Apple Watch typically records RHR during sleep periods
    ///
    /// ## Example Usage
    /// ```swift
    /// let personalData = DefaultPersonalDataManager()
    ///
    /// // Get last 7 days for weekly RHR trend
    /// let weekHistory = try await personalData.getRestingHeartRateHistory(days: 7)
    /// for (index, dayData) in weekHistory.enumerated() {
    ///     if let data = dayData {
    ///         print("Day \(index + 1): \(data.value) bpm")
    ///     } else {
    ///         print("Day \(index + 1): No data")
    ///     }
    /// }
    ///
    /// // Calculate RHR variability over 30 days
    /// let monthHistory = try await personalData.getRestingHeartRateHistory(days: 30)
    /// let validDays = monthHistory.compactMap { $0?.value }
    /// let minRHR = validDays.min()
    /// let maxRHR = validDays.max()
    /// ```
    ///
    /// ## Common Use Cases
    /// - **Recovery Monitoring**: Track RHR trends to assess training adaptation
    /// - **Chart Visualization**: Plot daily RHR in Swift Charts for trend analysis
    /// - **Baseline Comparison**: Compare current RHR against historical baseline
    /// - **Training Load Assessment**: Identify elevated RHR indicating inadequate recovery
    ///
    /// ## Notes
    /// - Returned array length always equals the requested `days` parameter
    /// - Missing data (nil values) can occur if:
    ///   - User didn't wear Apple Watch overnight
    ///   - Heart rate tracking was disabled
    ///   - Data hasn't synced yet
    /// - Consider using `compactMap` when you need only valid RHR entries
    /// - Elevated RHR (>5-10 bpm above baseline) may indicate overtraining or illness
    func getRestingHeartRateHistory(days: Int) async throws -> [HealthKitData?]
    
    /// Retrieves heart rate variability data for each of the last N nights as individual data points.
    ///
    /// Fetches HRV data for each night separately, returning an array where each element
    /// represents one night's average HRV measurement. This is useful for tracking autonomic
    /// nervous system recovery and identifying patterns in cardiovascular health.
    ///
    /// - Parameter nights: Number of nights to retrieve (e.g., 7 for last week, 30 for last month)
    /// - Returns: Array of `HealthKitData?` where:
    ///   - Each element represents one night's HRV in milliseconds (ms)
    ///   - `nil` elements indicate nights with no HRV data available
    ///   - Array is ordered chronologically (oldest first, most recent last)
    /// - Throws: HealthKit errors if data access fails
    ///
    /// ## Implementation Details
    /// - Uses sleep window (8 PM previous day → 10 AM) for each night
    /// - Averages all HRV measurements within the window
    /// - Each data point uses the window end time (10 AM) as its timestamp
    /// - Apple Watch records HRV during sleep in deep sleep stages
    /// - Higher HRV generally indicates better recovery and parasympathetic tone
    ///
    /// ## Example Usage
    /// ```swift
    /// let personalData = DefaultPersonalDataManager()
    ///
    /// // Get last 7 nights for weekly HRV trend
    /// let weekHistory = try await personalData.getHeartRateVariabilityHistory(nights: 7)
    /// for (index, nightData) in weekHistory.enumerated() {
    ///     if let data = nightData {
    ///         print("Night \(index + 1): \(data.value) ms")
    ///     } else {
    ///         print("Night \(index + 1): No data")
    ///     }
    /// }
    ///
    /// // Identify recovery trends over 14 nights
    /// let twoWeeks = try await personalData.getHeartRateVariabilityHistory(nights: 14)
    /// let validNights = twoWeeks.compactMap { $0?.value }
    /// let recentWeek = validNights.suffix(7)
    /// let previousWeek = validNights.prefix(7)
    /// let trend = recentWeek.reduce(0, +) / 7.0 - previousWeek.reduce(0, +) / 7.0
    /// print("HRV trend: \(trend > 0 ? "improving" : "declining")")
    /// ```
    ///
    /// ## Common Use Cases
    /// - **Recovery Assessment**: Monitor HRV to determine training readiness
    /// - **Stress Tracking**: Detect periods of elevated stress or fatigue
    /// - **Chart Visualization**: Display HRV trends to identify recovery patterns
    /// - **Training Optimization**: Adjust training intensity based on HRV trends
    ///
    /// ## Notes
    /// - Returned array length always equals the requested `nights` parameter
    /// - Missing data (nil values) can occur if:
    ///   - User didn't wear Apple Watch during sleep
    ///   - Sleep tracking was disabled
    ///   - Insufficient deep sleep for HRV measurement
    /// - Consider using `compactMap` when you need only valid HRV entries
    /// - Declining HRV trend may indicate accumulated fatigue or overtraining
    /// - HRV is highly individual - compare against personal baseline, not absolute values
    func getHeartRateVariabilityHistory(nights: Int) async throws -> [HealthKitData?]
    
    /// Retrieves active energy burned data for each of the last N days as individual data points.
    ///
    /// Fetches daily active energy expenditure separately, returning an array where each element
    /// represents one day's total caloric burn from physical activity. This is useful for
    /// tracking training load, activity patterns, and cumulative weekly/monthly energy expenditure.
    ///
    /// - Parameter days: Number of days to retrieve (e.g., 7 for last week, 30 for last month)
    /// - Returns: Array of `HealthKitData?` where:
    ///   - Each element represents one day's active energy in kilocalories (kcal)
    ///   - `nil` elements indicate days with no activity data available
    ///   - Array is ordered chronologically (oldest first, most recent last)
    /// - Throws: HealthKit errors if data access fails
    ///
    /// ## Implementation Details
    /// - Uses full calendar day (00:00 - 23:59) for each day
    /// - Includes all physical activity energy (excludes basal metabolic rate)
    /// - Each data point uses the day's end time (23:59) as its timestamp
    /// - Cumulative sum of all active energy samples throughout the day
    /// - Includes energy from workouts, daily movement, and exercise
    ///
    /// ## Example Usage
    /// ```swift
    /// let personalData = DefaultPersonalDataManager()
    ///
    /// // Get last 7 days for weekly activity chart
    /// let weekHistory = try await personalData.getActiveEnergyBurnedHistory(days: 7)
    /// for (index, dayData) in weekHistory.enumerated() {
    ///     if let data = dayData {
    ///         print("Day \(index + 1): \(data.value) kcal")
    ///     } else {
    ///         print("Day \(index + 1): No data")
    ///     }
    /// }
    ///
    /// // Calculate weekly training load
    /// let weekData = try await personalData.getActiveEnergyBurnedHistory(days: 7)
    /// let weeklyTotal = weekData.compactMap { $0?.value }.reduce(0, +)
    /// print("Weekly active energy: \(weeklyTotal) kcal")
    ///
    /// // Compare current week to previous week
    /// let twoWeeks = try await personalData.getActiveEnergyBurnedHistory(days: 14)
    /// let currentWeek = twoWeeks.suffix(7).compactMap { $0?.value }.reduce(0, +)
    /// let previousWeek = twoWeeks.prefix(7).compactMap { $0?.value }.reduce(0, +)
    /// let change = ((currentWeek - previousWeek) / previousWeek) * 100
    /// print("Activity change: \(change)%")
    /// ```
    ///
    /// ## Common Use Cases
    /// - **Training Load Tracking**: Monitor daily and cumulative activity levels
    /// - **Chart Visualization**: Display daily energy expenditure in bar/line charts
    /// - **Weekly Planning**: Assess whether training volume is increasing appropriately
    /// - **Recovery Balance**: Identify high-load periods requiring additional recovery
    /// - **Caloric Balance**: Track energy expenditure for nutrition planning
    ///
    /// ## Notes
    /// - Returned array length always equals the requested `days` parameter
    /// - Missing data (nil values) can occur if:
    ///   - User didn't wear Apple Watch throughout the day
    ///   - Activity tracking was disabled
    ///   - No physical activity occurred (rest day)
    /// - Consider using `compactMap` when you need only valid activity days
    /// - Values include all movement (workouts + daily activity) but exclude BMR
    /// - Sharp increases in daily energy (>20% week-over-week) may indicate overtraining risk
    func getActiveEnergyBurnedHistory(days: Int) async throws -> [HealthKitData?]
}
