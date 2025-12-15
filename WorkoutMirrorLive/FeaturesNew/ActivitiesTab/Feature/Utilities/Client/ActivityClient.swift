//
//  ActivityClient.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 13/12/2025.
//

import ComposableArchitecture
import HealthKit
import HealthHub
import SharedModels

public struct ActivityClient: Sendable {
    public var fetchWorkouts: @Sendable (Int, ActivitiesSortOption) async throws -> [HKWorkout]
}

extension ActivityClient: DependencyKey {
    public static let liveValue = ActivityClient(
        fetchWorkouts: { days, sortOption in
            @Dependency(\.activityManager) var activityManager
            return try await activityManager.fetchWorkouts(
                for: days,
                sortBy: sortOption
            )
        }
    )
    
    public static let testValue = ActivityClient(
        fetchWorkouts: unimplemented("ActivityClient.fetchWorkouts")
    )
}

extension DependencyValues {
    public var activityClient: ActivityClient {
        get { self[ActivityClient.self] }
        set { self[ActivityClient.self] = newValue }
    }
}
