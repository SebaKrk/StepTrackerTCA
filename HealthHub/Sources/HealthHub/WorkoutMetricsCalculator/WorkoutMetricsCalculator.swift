//
//  WorkoutMetricsCalculator.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 31/12/2025.
//

import Foundation
import SharedModels

/// Calculator for workout performance metrics.
///
/// Provides pure mathematical calculations for training metrics like METs, TRIMP, and hrTSS.
/// All methods are synchronous and have no external dependencies - they only perform calculations
/// on provided input data.
///
/// ## Usage
/// ```swift
/// let calculator = DefaultWorkoutMetricsCalculator()
///
/// let mets = calculator.calculateMETs(
///     activeCalories: 450,
///     weightKg: 80,
///     durationSeconds: 3600
/// )
/// // mets = 5.625
/// ```
public protocol WorkoutMetricsCalculator: Sendable {
    
    // MARK: - Energy & Intensity
    
    /// Calculates METs (Metabolic Equivalent of Task) for a workout.
    ///
    /// METs indicate how many times more energy was expended compared to rest.
    /// - 1 MET = resting energy expenditure
    /// - 3-6 METs = moderate activity
    /// - 6-9 METs = vigorous activity
    /// - 9+ METs = very vigorous activity
    ///
    /// Formula: `METs = activeCalories / (weightKg × durationHours)`
    ///
    /// - Parameters:
    ///   - activeCalories: Active energy burned during workout (kcal)
    ///   - weightKg: User's body weight in kilograms
    ///   - durationSeconds: Workout duration in seconds
    /// - Returns: METs value, or nil if inputs are invalid
    func calculateMETs(
        activeCalories: Double,
        weightKg: Double,
        durationSeconds: TimeInterval
    ) -> Double?
    
    // MARK: - Training Load
    
    /// Calculates TRIMP (Training Impulse) from heart rate zone distribution.
    ///
    /// TRIMP quantifies training load by weighting time spent in each HR zone.
    /// Higher zones contribute more to the total load.
    ///
    /// Zone coefficients:
    /// - Zone 1 (Resting): ×1
    /// - Zone 2 (Recovery): ×2
    /// - Zone 3 (Fat Burning): ×3
    /// - Zone 4 (Aerobic): ×4
    /// - Zone 5 (Threshold): ×5
    /// - Zone 6 (Anaerobic): ×6
    ///
    /// - Parameter zoneDistribution: Time spent in each heart rate zone (seconds)
    /// - Returns: TRIMP score
    func calculateTRIMP(
        zoneDistribution: [HeartRateZone: TimeInterval]
    ) -> Double
    
    /// Calculates hrTSS (Heart Rate Training Stress Score).
    ///
    /// hrTSS normalizes training stress where 100 = 1 hour at lactate threshold.
    /// Used to estimate recovery needs:
    /// - <150: Full recovery next day
    /// - 150-300: Fatigue for 1-2 days
    /// - 300-450: Fatigue for 2-4 days
    /// - 450+: Requires 5+ days recovery
    ///
    /// - Parameters:
    ///   - avgHR: Average heart rate during workout
    ///   - restingHR: User's resting heart rate
    ///   - maxHR: User's maximum heart rate
    ///   - durationMinutes: Workout duration in minutes
    ///   - trimp: Previously calculated TRIMP value
    /// - Returns: hrTSS score, or nil if heart rate reserve is invalid
    func calculateHRTSS(
        avgHR: Double,
        restingHR: Double,
        maxHR: Double,
        durationMinutes: Double,
        trimp: Double
    ) -> Double?
    
    // MARK: - Recovery
    
    /// Calculates HR Recovery (heart rate drop after 1 minute).
    ///
    /// Indicates cardiovascular fitness and recovery capacity:
    /// - <12 bpm: Poor recovery, possible overtraining
    /// - 12-20 bpm: Average
    /// - 20-30 bpm: Good
    /// - 30-40 bpm: Very good
    /// - 40+ bpm: Excellent (athlete level)
    ///
    /// - Parameters:
    ///   - maxHRDuringWorkout: Maximum HR reached during workout
    ///   - hrAfter1Minute: Heart rate 1 minute after workout end
    /// - Returns: HR drop in bpm
    func calculateHRRecovery(
        maxHRDuringWorkout: Double,
        hrAfter1Minute: Double
    ) -> Int
    
    // MARK: - Utility
    
    /// Calculates calories burned per minute.
    ///
    /// - Parameters:
    ///   - totalCalories: Total calories burned
    ///   - durationSeconds: Duration in seconds
    /// - Returns: Calories per minute, or nil if duration is zero
    func calculateCaloriesPerMinute(
        totalCalories: Double,
        durationSeconds: TimeInterval
    ) -> Double?
    
    // MARK: - Comparison
    
    /// Compares current value to average for trend display.
    ///
    /// Used for UI elements like "▲ +12% vs 7d"
    ///
    /// - Parameters:
    ///   - currentValue: Today's or current workout value
    ///   - averageValue: Historical average (e.g., 7-day average)
    /// - Returns: Comparison with difference, percentage, and trend direction
    func calculateComparison(
        currentValue: Double,
        averageValue: Double
    ) -> MetricComparison
}
