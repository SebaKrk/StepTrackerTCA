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
    ///
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
}
