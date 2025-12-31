//
//  WorkoutMetricsManager.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 31/12/2025.
//

import Foundation
import HealthKit
import SharedModels

/// Manager for fetching and calculating workout performance metrics.
///
/// Coordinates data retrieval from HealthKit and delegates calculations
/// to `WorkoutMetricsCalculator`. Handles all async operations and data assembly.
///
/// ## Architecture
/// ```
/// WorkoutMetricsManager (this - data fetching & coordination)
///         │
///         ├── uses: PersonalDataManager (weight, resting HR)
///         ├── uses: ActivityManager (HR samples, workouts)
///         ├── uses: WorkoutZoneAnalyzer (zone distribution)
///         └── uses: WorkoutMetricsCalculator (pure calculations)
/// ```
///
/// ## Usage
/// ```swift
/// @Dependency(\.workoutMetricsManager) var metricsManager
///
/// let mets = try await metricsManager.fetchMETs(for: workout)
/// let trimp = try await metricsManager.fetchTRIMP(for: workout, maxHeartRate: 185)
/// ```
public protocol WorkoutMetricsManager: Sendable {
    
    // MARK: - Single Workout Metrics
    
    /// Fetches METs (Metabolic Equivalent of Task) for a specific workout.
    ///
    /// Retrieves user's weight from the workout date and calculates METs.
    /// METs indicate exercise intensity compared to rest:
    /// - 1 MET = resting
    /// - 3-6 METs = moderate activity
    /// - 6-9 METs = vigorous activity
    /// - 9+ METs = very vigorous activity
    ///
    /// - Parameter workout: The workout to analyze
    /// - Returns: METs value, or nil if weight or calorie data unavailable
    func fetchMETs(for workout: HKWorkout) async throws -> Double?
    
    /// Fetches TRIMP (Training Impulse) for a specific workout.
    ///
    /// TRIMP quantifies training load by weighting time spent in each HR zone.
    /// Typical values:
    /// - 50-100 = light training
    /// - 100-200 = moderate training
    /// - 200-300 = hard training
    /// - 300+ = very hard training
    ///
    /// - Parameters:
    ///   - workout: The workout to analyze
    ///   - maxHeartRate: User's maximum heart rate for zone calculation
    /// - Returns: TRIMP score
    func fetchTRIMP(for workout: HKWorkout, maxHeartRate: Double) async throws -> Double
    
    /// Fetches hrTSS (Heart Rate Training Stress Score) for a specific workout.
    ///
    /// hrTSS normalizes training stress where 100 = 1 hour at lactate threshold.
    /// Used to estimate recovery needs:
    /// - <150: Full recovery next day
    /// - 150-300: Fatigue for 1-2 days
    /// - 300-450: Fatigue for 2-4 days
    /// - 450+: Requires 5+ days recovery
    ///
    /// - Parameters:
    ///   - workout: The workout to analyze
    ///   - maxHeartRate: User's maximum heart rate
    /// - Returns: hrTSS score, or nil if resting HR or avg HR unavailable
    func fetchHRTSS(for workout: HKWorkout, maxHeartRate: Double) async throws -> Double?
    
    /// Fetches HR Recovery (heart rate drop 1 minute after workout).
    ///
    /// Indicates cardiovascular fitness and recovery capacity:
    /// - <12 bpm drop: Poor recovery, possible overtraining
    /// - 12-20 bpm: Average
    /// - 20-30 bpm: Good
    /// - 30-40 bpm: Very good
    /// - 40+ bpm: Excellent (athlete level)
    ///
    /// - Parameter workout: The workout to analyze
    /// - Returns: HR drop in bpm, or nil if post-workout HR data unavailable
    func fetchHRRecovery(for workout: HKWorkout) async throws -> Int?
    
    // MARK: - Historical Data (for charts)
    
    // TODO: Implement when building charts feature
    //
    // /// Fetches METs history for past workouts.
    // /// - Parameter days: Number of days to look back
    // /// - Returns: Array of (date, value) for charting
    // func fetchMETsHistory(days: Int) async throws -> [(Date, Double)]
    //
    // /// Fetches TRIMP history for past workouts.
    // /// - Parameters:
    // ///   - days: Number of days to look back
    // ///   - maxHeartRate: User's maximum heart rate
    // /// - Returns: Array of (date, value) for charting
    // func fetchTRIMPHistory(days: Int, maxHeartRate: Double) async throws -> [(Date, Double)]
}
