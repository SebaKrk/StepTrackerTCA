//
//  HeartRateDetailsService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 25/04/2025.
//

import HealthKit

protocol HeartRateDetailsService {
    func fetchHeartRateSamples(for workout: HKWorkout) async throws -> [HKQuantitySample]
}
