//
//  DefaultHeartRateDetailsService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 25/04/2025.
//

import Factory
import Foundation
import HealthKit

final class DefaultHeartRateDetailsService: HeartRateDetailsService {
    
    // MARK: - Dependency
    
    @Injected(\.healthKitManager) private var healthKitManager
    
    // MARK: - API
    
    func fetchHeartRateSamples(for workout: HKWorkout) async throws -> [HKQuantitySample] {
        try await healthKitManager.fetchHeartRateSamples(for: workout)
    }
    
    func calculateMinuteHRStats(from samples: [HKQuantitySample]) -> [HeartRateMetricsMinute] {
        let calendar = Calendar.current
        
        let grouped = Dictionary(grouping: samples) { sample in
            calendar.dateInterval(of: .minute, for: sample.startDate)!.start
        }

        let stats = grouped.map { minuteStart, groupSamples in
            let values = groupSamples.map {
                $0.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
            }
            let minHR = values.min() ?? 0
            let maxHR = values.max() ?? 0
            return HeartRateMetricsMinute(minute: minuteStart, minHR: minHR, maxHR: maxHR)
        }

        return stats.sorted { $0.minute < $1.minute }
    }
    
    func fetchActiveEnergyBurned(for workout: HKWorkout) async throws -> Double {
        try await healthKitManager.fetchActiveEnergyBurned(for: workout)
    }
    
}
