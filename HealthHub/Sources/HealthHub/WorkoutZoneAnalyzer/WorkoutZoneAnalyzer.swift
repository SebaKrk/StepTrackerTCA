
//
//  WorkoutZoneAnalyzer.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 23/12/2025.
//

import HealthKit
import SharedModels

/// Analyzer for calculating heart rate zone distribution during workouts.
public protocol WorkoutZoneAnalyzer: Sendable {
    
    /// Analyzes heart rate samples and returns the primary zone (longest time spent).
    ///
    /// - Parameters:
    ///   - samples: Array of heart rate samples from a workout
    ///   - maxHeartRate: User's maximum heart rate for zone calculation
    /// - Returns: PrimaryZoneInfo with the dominant zone and duration, or nil if insufficient samples
    func analyzePrimaryZone(
        samples: [HKQuantitySample],
        maxHeartRate: Double
    ) -> PrimaryZoneInfo?
    
    /// Calculates time spent in each heart rate zone.
    ///
    /// - Parameters:
    ///   - samples: Chronologically sorted heart rate samples
    ///   - maxHeartRate: User's maximum heart rate
    /// - Returns: Dictionary mapping each zone to total seconds spent
    func calculateZoneDistribution(
        samples: [HKQuantitySample],
        maxHeartRate: Double
    ) -> [HeartRateZone: TimeInterval]
    
    /// Determines which heart rate zone a given heart rate falls into.
    ///
    /// - Parameters:
    ///   - heartRate: Current heart rate in BPM
    ///   - maxHeartRate: User's maximum heart rate
    /// - Returns: The corresponding HeartRateZone
    func determineZone(
        heartRate: Double,
        maxHeartRate: Double
    ) -> HeartRateZone
}
