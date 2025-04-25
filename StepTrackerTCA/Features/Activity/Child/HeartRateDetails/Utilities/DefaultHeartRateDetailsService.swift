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
    
}
