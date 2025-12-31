//
//  DefaultWorkoutMetricsCalculator.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 31/12/2025.
//

import Foundation
import SharedModels

public final class DefaultWorkoutMetricsCalculator: WorkoutMetricsCalculator {
    
    // MARK: - Lifecycle
    
    public init() {}
    
    // MARK: - Energy & Intensity
    
    public func calculateMETs(
        activeCalories: Double,
        weightKg: Double,
        durationSeconds: TimeInterval
    ) -> Double? {
        guard activeCalories > 0,
              weightKg > 0,
              durationSeconds > 0
        else { return nil }
        
        let durationHours = durationSeconds / 3600
        return activeCalories / (weightKg * durationHours)
    }
    
    // MARK: - Training Load
    
    public func calculateTRIMP(
        zoneDistribution: [HeartRateZone: TimeInterval]
    ) -> Double {
        let coefficients: [HeartRateZone: Double] = [
            .resting: 1.0,
            .recovery: 2.0,
            .fatBurning: 3.0,
            .aerobic: 4.0,
            .threshold: 5.0,
            .anaerobic: 6.0
        ]
        
        return zoneDistribution.reduce(0.0) { total, entry in
            let minutes = entry.value / 60
            let coefficient = coefficients[entry.key] ?? 1.0
            return total + (minutes * coefficient)
        }
    }
    
    public func calculateHRTSS(
        avgHR: Double,
        restingHR: Double,
        maxHR: Double,
        durationMinutes: Double,
        trimp: Double
    ) -> Double? {
        let hrReserve = maxHR - restingHR
        guard hrReserve > 0 else { return nil }
        
        let intensityFactor = (avgHR - restingHR) / hrReserve
        return (durationMinutes * intensityFactor * trimp) / 100
    }
    
    // MARK: - Recovery
    
    public func calculateHRRecovery(
        maxHRDuringWorkout: Double,
        hrAfter1Minute: Double
    ) -> Int {
        Int(maxHRDuringWorkout - hrAfter1Minute)
    }
    
    // MARK: - Utility
    
    public func calculateCaloriesPerMinute(
        totalCalories: Double,
        durationSeconds: TimeInterval
    ) -> Double? {
        guard durationSeconds > 0 else { return nil }
        let durationMinutes = durationSeconds / 60
        return totalCalories / durationMinutes
    }
    
    // MARK: - Comparison
    
    public func calculateComparison(
        currentValue: Double,
        averageValue: Double
    ) -> MetricComparison {
        let difference = currentValue - averageValue
        
        let percentageChange: Double
        if averageValue > 0 {
            percentageChange = (difference / averageValue) * 100
        } else {
            percentageChange = 0
        }
        
        let trend: MetricComparison.Trend
        if abs(percentageChange) < 2 {
            trend = .neutral
        } else if difference > 0 {
            trend = .up
        } else {
            trend = .down
        }
        
        return MetricComparison(
            difference: difference,
            percentageChange: percentageChange,
            trend: trend
        )
    }
}
