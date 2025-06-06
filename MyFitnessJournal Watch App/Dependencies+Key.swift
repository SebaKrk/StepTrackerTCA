//
//  Dependencies+Key.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 28/05/2025.
//
//  This file registers HealthKit-related dependencies used across the app
//  within the TCA Dependency System.
//

import ComposableArchitecture
import HealthKit

/// A TCA dependency key for accessing the live implementation of the training manager.
private enum TrainingManagerKey: DependencyKey {
    static let liveValue: TrainingManager = {
        @Dependency(\.healthStore) var healthStore
        return DefaultTrainingManager(healthStore: healthStore)
    }()
}

extension DependencyValues {
    var trainingManager: TrainingManager {
        get { self[TrainingManagerKey.self] }
        set { self[TrainingManagerKey.self] = newValue }
    }
}

/// A TCA dependency key for managing HealthKit authorization logic.
private enum AuthorizationManagerKey: DependencyKey {
    static let liveValue: AuthorizationManager = {
        @Dependency(\.healthStore) var healthStore
        return DefaultAuthorizationManager(healthStore: healthStore)
    }()
}

extension DependencyValues {
    var authorizationManager: AuthorizationManager {
        get { self[AuthorizationManagerKey.self] }
        set { self[AuthorizationManagerKey.self] = newValue }
    }
}

/// A TCA dependency key for managing  Activity Ring.
private enum ActivityRingManagerKey: DependencyKey {
    static let liveValue:  ActivityRingManager = {
        @Dependency(\.healthStore) var healthStore
        return DefaultActivityRingManager(healthStore: healthStore)
    }()
}

extension DependencyValues {
    var activityRingManager:  ActivityRingManager {
        get { self[ActivityRingManagerKey.self] }
        set { self[ActivityRingManagerKey.self] = newValue }
    }
}

/// A TCA dependency key for accessing a shared instance of HKHealthStore.
private enum HealthStoreKey: DependencyKey {
    static let liveValue: HKHealthStore = HKHealthStore()
}

extension DependencyValues {
    var healthStore: HKHealthStore {
        get { self[HealthStoreKey.self] }
        set { self[HealthStoreKey.self] = newValue }
    }
}
