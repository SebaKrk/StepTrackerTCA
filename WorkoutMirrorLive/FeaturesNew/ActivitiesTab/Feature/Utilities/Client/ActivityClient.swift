//
//  ActivityClient.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 13/12/2025.
//

import ComposableArchitecture
import HealthKit
import HealthHub

@DependencyClient
public struct ActivityClient: Sendable {
    public var fetchWorkouts: @Sendable (Int, [SortDescriptor<HKWorkout>]) async throws -> [HKWorkout] = { _, _ in [] }
}

extension ActivityClient: DependencyKey {
    public static let liveValue: ActivityClient = {
        
        @Dependency(\.authorizationManager) var authManager
        
        let activityManager = DefaultActivityManager(healthStore: authManager.healthStore)
        
        return Self(
            fetchWorkouts: { days, sortDescriptors in
                try await activityManager.fetchWorkouts(
                    for: days,
                    sortBy: sortDescriptors
                )
            }
        )
    }()
}

extension DependencyValues {
    public var activityClient: ActivityClient {
        get { self[ActivityClient.self] }
        set { self[ActivityClient.self] = newValue }
    }
}
