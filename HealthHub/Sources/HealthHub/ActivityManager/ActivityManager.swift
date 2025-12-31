//
//  ActivityManager.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 13/12/2025.
//

import HealthKit
import SharedModels

/// Manager for fetching and analyzing historical workout data.
public protocol ActivityManager: Sendable {
    
    /// Fetches a list of workouts from the specified time period.
    ///
    /// - Parameters:
    ///   - days: Number of days to look back from today
    ///   - option: Sort option to order results
    /// - Returns: Array of `HKWorkout` objects from the specified period
    /// - Throws: HealthKit errors if data access fails
    func fetchWorkouts(
        for days: Int,
        sortBy option: ActivitiesSortOption
    ) async throws -> [HKWorkout]
    
    /// Fetches heart rate samples recorded during a specific workout.
    ///
    /// - Parameter workout: The workout to fetch heart rate data for
    /// - Returns: Array of heart rate samples sorted chronologically
    /// - Throws: HealthKit errors if data access fails
    func fetchHeartRateSamples(
        for workout: HKWorkout
    ) async throws -> [HKQuantitySample]
    
    /// Fetches heart rate measurement after workout ends.
    ///
    /// Used for HR Recovery calculation - measures how quickly heart rate
    /// drops after exercise stops. A faster drop indicates better cardiovascular fitness.
    ///
    /// - Parameters:
    ///   - workout: The completed workout
    ///   - afterSeconds: Seconds after workout end to measure (typically 60 for HRR1)
    /// - Returns: Heart rate in bpm, or nil if no data available in the time window
    /// - Throws: HealthKit errors if data access fails
    func fetchHeartRateAfterWorkout(
        workout: HKWorkout,
        afterSeconds: TimeInterval
    ) async throws -> Double?
}
