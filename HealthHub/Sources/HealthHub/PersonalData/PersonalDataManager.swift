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
protocol PersonalDataManager {
    
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
    /// human-readable string representation.
    ///
    /// - Returns: A string representation of biological sex ("Male", "Female", "Other", "Not Set"),
    ///           or `nil` if not available
    /// - Throws: HealthKit errors if data access fails
    func getBiologicalSex() async throws -> String?
    
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
    /// - Parameter days: Number of days to look back for averaging (default: 1)
    /// - Returns: A `HealthKitData` object containing the weight measurement in kilograms,
    ///           or `nil` if no weight data is available
    /// - Throws: HealthKit errors if data access fails
    func getWeight(days: Int) async throws -> HealthKitData?
    
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
    
}
