//
//  HeartRateDetailsService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 25/04/2025.
//

import HealthKit

protocol HeartRateDetailsService {
    
    /// Fetches heart rate quantity samples associated with a given workout.
    /// - Parameter workout: The workout for which to fetch heart rate samples.
    /// - Returns: An array of `HKQuantitySample` representing heart rate data.
    func fetchHeartRateSamples(for workout: HKWorkout) async throws -> [HKQuantitySample]
    
    /// Calculates per-minute heart rate metrics from the provided heart rate samples.
    /// - Parameter samples: The heart rate samples to analyze.
    /// - Returns: An array of `HeartRateMetricsMinute` representing summarized per-minute statistics.
    func calculateMinuteHRStats(from samples: [HKQuantitySample]) -> [HeartRateMetricsMinute]
    
    /// Fetches the amount of active energy burned during the given workout.
    /// - Parameter workout: The workout for which to fetch the active energy burned.
    /// - Returns: The active energy burned as a `Double` value.
    func fetchActiveEnergyBurned(for workout: HKWorkout) async throws -> Double
    
    /// Returns the heart rate metric corresponding to the selected minute, if available.
    ///
    /// - Parameters:
    ///   - heartRateMetric: An array of `HeartRateMetricsMinute` values to search through.
    ///   - rawSelectedDate: An optional `Date` representing the selected time.
    /// - Returns: A `HeartRateMetricsMinute` object that matches the selected minute, or `nil` if no match is found.
    ///
    /// This method compares the provided `rawSelectedDate` to each metric's `minute` value using `.minute` granularity.
    func selectedHealthMetric(from heartRateMetric: [HeartRateMetricsMinute], with rawSelectedDate: Date?) -> HeartRateMetricsMinute?
    
}
