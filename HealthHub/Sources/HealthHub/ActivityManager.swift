//
//  ActivityManager.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 13/12/2025.
//

import HealthKit

/// Manager do pobierania i analizy historycznych danych treningowych
public protocol ActivityManager: Sendable {
    
    /// Pobiera listę treningów z określonego okresu
    func fetchWorkouts(
        for days: Int,
        sortBy sortDescriptors: [SortDescriptor<HKWorkout>]
    ) async throws -> [HKWorkout]
}


import HealthKit

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
        sortBy sortDescriptors: [SortDescriptor<HKWorkout>]
    ) async throws -> [HKWorkout] {
        try await HealthKitQueryBuilder.fetchWorkoutsWithDescriptor(
            for: days,
            sortDescriptors: sortDescriptors,
            healthStore: healthStore
        )
    }
}
