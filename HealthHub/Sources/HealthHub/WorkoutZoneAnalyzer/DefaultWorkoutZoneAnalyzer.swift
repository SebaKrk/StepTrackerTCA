//
//  DefaultWorkoutZoneAnalyzer.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 23/12/2025.
//

import HealthKit
import SharedModels

public final class DefaultWorkoutZoneAnalyzer: WorkoutZoneAnalyzer {
    
    // MARK: - Lifecycle
    
    public init() {}
    
    // MARK: - WorkoutZoneAnalyzer Protocol
    
    /// Analyzes heart rate samples and returns the primary zone (longest time spent).
    ///
    /// Resting is not a training zone — a strength workout with long rests can
    /// accumulate most of its time below 50% maxHR, yet "Resting" as the headline
    /// zone reads as "no training happened". The dominant TRAINING zone wins;
    /// resting is returned only when no training zone has any time at all.
    public func analyzePrimaryZone(
        samples: [HKQuantitySample],
        maxHeartRate: Double
    ) -> PrimaryZoneInfo? {
        guard samples.count >= 2 else { return nil }

        let distribution = calculateZoneDistribution(
            samples: samples,
            maxHeartRate: maxHeartRate
        )

        let trainingDistribution = distribution.filter { $0.key != .resting && $0.value > 0 }

        if let primaryEntry = trainingDistribution.max(by: { $0.value < $1.value }) {
            return PrimaryZoneInfo(
                zone: primaryEntry.key,
                duration: primaryEntry.value
            )
        }

        guard let restingDuration = distribution[.resting], restingDuration > 0 else {
            return nil
        }

        return PrimaryZoneInfo(zone: .resting, duration: restingDuration)
    }
    
    /// Calculates time spent in each heart rate zone.
    public func calculateZoneDistribution(
        samples: [HKQuantitySample],
        maxHeartRate: Double
    ) -> [HeartRateZone: TimeInterval] {
        var distribution: [HeartRateZone: TimeInterval] = [:]
        
        guard samples.count > 1 else { return distribution }
        
        for zone in HeartRateZone.allCases {
            distribution[zone] = 0
        }
        
        let unit = HKUnit.count().unitDivided(by: .minute())
        
        for i in 0..<(samples.count - 1) {
            let currentSample = samples[i]
            let nextSample = samples[i + 1]
            
            let heartRate = currentSample.quantity.doubleValue(for: unit)
            let duration = nextSample.startDate.timeIntervalSince(currentSample.startDate)
            
            guard duration > 0, duration < 300 else { continue }
            
            let zone = determineZone(heartRate: heartRate, maxHeartRate: maxHeartRate)
            distribution[zone, default: 0] += duration
        }

        return distribution
    }
    
    /// Determines which heart rate zone a given heart rate falls into.
    public func determineZone(
        heartRate: Double,
        maxHeartRate: Double
    ) -> HeartRateZone {
        HeartRateZone.zone(heartRate: heartRate, maxHeartRate: maxHeartRate)
    }
    
}
