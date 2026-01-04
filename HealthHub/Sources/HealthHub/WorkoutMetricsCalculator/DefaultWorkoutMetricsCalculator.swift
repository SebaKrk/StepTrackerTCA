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
        durationMinutes: Double
    ) -> Double? {
        guard avgHR > 0,
              maxHR > 0,
              avgHR <= maxHR,
              durationMinutes > 0 else {
            return nil
        }
        let thresholdHR = maxHR * 0.93
        let intensityFactor = max(avgHR / thresholdHR, 0)
        let durationHours = durationMinutes / 60.0
        let hrTSS = durationHours * pow(intensityFactor, 2) * 100
        
        //        print("🔍 hrTSS Calculation:")
        //        print("  Input:")
        //        print("    - avgHR: \(String(format: "%.1f", avgHR)) bpm")
        //        print("    - maxHR: \(String(format: "%.1f", maxHR)) bpm")
        //        print("    - duration: \(String(format: "%.1f", durationMinutes)) min (\(String(format: "%.2f", durationHours)) h)")
        //        print("  Calculated:")
        //        print("    - Threshold HR (est.): \(String(format: "%.1f", thresholdHR)) bpm (93% HRmax)")
        //        print("    - Intensity Factor: \(String(format: "%.3f", intensityFactor))")
        //        print("    - IF²: \(String(format: "%.3f", pow(intensityFactor, 2)))")
        //        print("  Result:")
        //        print("    - hrTSS: \(String(format: "%.1f", hrTSS))")
        
        return hrTSS
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
    
    // MARK: - Intensity
    
    public func calculateIntensityFactor(
        avgHR: Double,
        maxHR: Double
    ) -> Double? {
        guard avgHR > 0, maxHR > 0, avgHR <= maxHR else { return nil }
        
        let lthr = maxHR * 0.85  // Lactate Threshold Heart Rate
        return avgHR / lthr
    }

    // MARK: - RecoveryDemand
    
    public func calculateRecoveryDemand(
        hrTSS: Double,
        hrRecovery: Int?,
        hrvRatio: Double?,
        sleepHours: Double?
    ) -> Double {
        // Step 1: Base recovery from hrTSS
        let baseRecovery: Double
        switch hrTSS {
        case ..<30: baseRecovery = 12
        case 30..<50: baseRecovery = 18
        case 50..<80: baseRecovery = 28
        case 80..<120: baseRecovery = 42
        case 120..<160: baseRecovery = 56
        default: baseRecovery = 72
        }
        
        // Step 2: HRR modifier
        let hrrModifier: Double
        if let hrr = hrRecovery {
            switch hrr {
            case 40...: hrrModifier = 0.80
            case 30..<40: hrrModifier = 0.90
            case 20..<30: hrrModifier = 1.00
            case 10..<20: hrrModifier = 1.15
            default: hrrModifier = 1.30
            }
        } else {
            hrrModifier = 1.0
        }
        
        // Step 3: HRV modifier
        let hrvModifier: Double
        if let ratio = hrvRatio {
            switch ratio {
            case 1.10...: hrvModifier = 0.80
            case 1.00..<1.10: hrvModifier = 0.90
            case 0.90..<1.00: hrvModifier = 1.00
            case 0.80..<0.90: hrvModifier = 1.15
            default: hrvModifier = 1.30
            }
        } else {
            hrvModifier = 1.0
        }
        
        // Step 4: Sleep modifier
        let sleepModifier: Double
        if let hours = sleepHours {
            switch hours {
            case 8...: sleepModifier = 0.85
            case 7..<8: sleepModifier = 0.95
            case 6..<7: sleepModifier = 1.00
            case 5..<6: sleepModifier = 1.15
            default: sleepModifier = 1.30
            }
        } else {
            sleepModifier = 1.0
        }
        
        return baseRecovery * hrrModifier * hrvModifier * sleepModifier
    }
}
