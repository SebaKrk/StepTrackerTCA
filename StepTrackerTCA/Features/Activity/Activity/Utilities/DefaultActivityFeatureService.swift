//
//  DefaultActivityFeatureService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 25/04/2025.
//

import Factory
import Foundation
import HealthKit

final class DefaultActivityFeatureService: ActivityFeatureService {
   
    // MARK: - Dependency
    
    @Injected(\.healthKitManager) private var healthKitManager
    
    // MARK: - API
    
    func getWorkoutData() async throws -> [HKWorkout] {
        try await healthKitManager.fetchWorkouts(for: 50)
    }
    
}
