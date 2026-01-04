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
    /// hrTSS estimates how much recovery a workout requires and helps plan
    /// subsequent training sessions. The score is normalized so that:
    /// - 100 hrTSS ≈ 1 hour at lactate threshold intensity
    ///
    /// Unlike TRIMP, hrTSS focuses on recovery demand rather than total
    /// systemic training stress.
    ///
    /// Typical interpretation:
    /// - <150: Low recovery demand (next-day training usually unaffected)
    /// - 150–300: Moderate recovery demand (careful planning recommended)
    /// - 300–450: High recovery demand (limit hard sessions)
    /// - 450+: Very high recovery demand (extended recovery required)
    ///
    /// - Parameters:
    ///   - avgHR: Average heart rate during the workout
    ///   - restingHR: User's resting heart rate
    ///   - maxHR: User's maximum heart rate
    ///   - durationMinutes: Workout duration in minutes
    /// - Returns: hrTSS value, or nil if heart rate reserve is invalid
    func calculateHRTSS(
        avgHR: Double,
        restingHR: Double,
        maxHR: Double,
        durationMinutes: Double
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
    
    // MARK: - Intensity
    
    /// Calculates Intensity Factor (IF) for a workout.
    ///
    /// IF indicates how hard you worked relative to your lactate threshold.
    /// - < 0.75: Recovery / Easy
    /// - 0.75-0.85: Aerobic / Endurance
    /// - 0.85-0.95: Tempo / Threshold
    /// - 0.95-1.05: VO2max intervals
    /// - > 1.05: All-out / Race pace
    ///
    /// Formula: `IF = avgHR / LTHR` where `LTHR = maxHR × 0.85`
    ///
    /// - Parameters:
    ///   - avgHR: Average heart rate during workout
    ///   - maxHR: User's maximum heart rate
    /// - Returns: Intensity Factor value (typically 0.5 - 1.2)
    func calculateIntensityFactor(
        avgHR: Double,
        maxHR: Double
    ) -> Double?
    
    /// Calculates Recovery Demand based on training load and recovery metrics.
    ///
    /// Formula: base_hours × HRR_modifier × HRV_modifier × sleep_modifier
    ///
    /// - Parameters:
    ///   - hrTSS: Training stress score
    ///   - hrRecovery: Heart rate recovery (bpm drop after 1 min), optional
    ///   - hrvRatio: Morning HRV / 7-day average HRV, optional (default 1.0)
    ///   - sleepHours: Sleep duration, optional (default assumes normal)
    /// - Returns: Estimated recovery hours
    func calculateRecoveryDemand(
        hrTSS: Double,
        hrRecovery: Int?,
        hrvRatio: Double?,
        sleepHours: Double?
    ) -> Double
}
