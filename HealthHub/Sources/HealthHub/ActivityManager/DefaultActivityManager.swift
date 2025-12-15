//
//  DefaultActivityManager.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 14/12/2025.
//

import ComposableArchitecture
import HealthKit
import SharedModels

public final class DefaultActivityManager: ActivityManager {
    
    // MARK: - Properties
    
    let healthStore: HKHealthStore
    
    // MARK: - Lifecycle
    
    public init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }
    
    // MARK: - ActivityManager Protocol
    
    public func fetchWorkouts(
        for days: Int,
        sortBy option: ActivitiesSortOption = .newestFirst
    ) async throws -> [HKWorkout] {
        try await HealthKitQueryBuilder.fetchWorkoutsWithDescriptor(
            for: days,
            sortOption: option,
            healthStore: healthStore
        )
    }
    
}

