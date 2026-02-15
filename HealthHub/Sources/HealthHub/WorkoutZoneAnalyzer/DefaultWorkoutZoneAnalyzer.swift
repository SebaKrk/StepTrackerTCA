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
    public func analyzePrimaryZone(
        samples: [HKQuantitySample],
        maxHeartRate: Double
    ) -> PrimaryZoneInfo? {
        guard samples.count >= 2 else { return nil }
        
        let distribution = calculateZoneDistribution(
            samples: samples,
            maxHeartRate: maxHeartRate
        )
        
        guard let primaryEntry = distribution.max(by: { $0.value < $1.value }) else {
            return nil
        }
        
        return PrimaryZoneInfo(
            zone: primaryEntry.key,
            duration: primaryEntry.value
        )
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
        
        // 🔍 DEBUG - Zone distribution
//        print("═══════════════════════════════════════════════════")
//        if let firstSample = samples.first {
//            let formatter = DateFormatter()
//            formatter.dateFormat = "yyyy-MM-dd HH:mm"
//            print("💓 Workout time: \(formatter.string(from: firstSample.startDate))")
//        }
//        print("💓 HR Zone Analysis (maxHR: \(Int(maxHeartRate)) bpm)")
//        print("💓 Samples count: \(samples.count)")
//        for zone in HeartRateZone.allCases {
//            let seconds = distribution[zone] ?? 0
//            let minutes = Int(seconds / 60)
//            let secs = Int(seconds.truncatingRemainder(dividingBy: 60))
//            let percentage = zone.percentageRange
//            print("   \(zone.rawValue): \(minutes)m \(secs)s (\(Int(percentage.lowerBound * 100))-\(Int(percentage.upperBound * 100))% maxHR)")
//        }
//        print("═══════════════════════════════════════════════════")
        
        return distribution
    }
    
    /// Determines which heart rate zone a given heart rate falls into.
    public func determineZone(
        heartRate: Double,
        maxHeartRate: Double
    ) -> HeartRateZone {
        let percentage = heartRate / maxHeartRate
        
        return HeartRateZone.allCases.first { zone in
            zone.percentageRange.contains(percentage)
        } ?? .anaerobic
    }
    
}
