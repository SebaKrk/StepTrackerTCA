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
@available(iOS 26.0, *)
public enum WorkoutManagerKey: DependencyKey {
    public static let liveValue: WorkoutManager = {
        print("Dependency - 🚀 WorkoutManager: Starting creation at \(Date())")
        @Dependency(\.healthStore) var healthStore
        print("Dependency - 📦 WorkoutManagerKey: HealthStore dependency resolved")
        let manager = DefaultWorkoutManager(healthStore: healthStore)
        print("Dependency - ✅ WorkoutManagerKey: TrainingManager created successfully")
        return manager
    }()
}

@available(iOS 26.0, *)
public extension DependencyValues {
    var workoutManager: WorkoutManager {
        get { self[WorkoutManagerKey.self] }
        set { self[WorkoutManagerKey.self] = newValue }
    }
}


/// A TCA dependency key for accessing the live implementation of the training manager.
public enum TrainingManagerKey: DependencyKey {
    public static let liveValue: TrainingManager = {
        print("Dependency - 🚀 TrainingManagerKey: Starting creation at \(Date())")
        @Dependency(\.healthStore) var healthStore
        print("Dependency - 📦 TrainingManagerKey: HealthStore dependency resolved")
        let manager = DefaultTrainingManager(healthStore: healthStore)
        print("Dependency - ✅ TrainingManagerKey: TrainingManager created successfully")
        return manager
    }()
}

public extension DependencyValues {
    var trainingManager: TrainingManager {
        get { self[TrainingManagerKey.self] }
        set { self[TrainingManagerKey.self] = newValue }
    }
}

/// A TCA dependency key for managing HealthKit authorization logic.
public enum AuthorizationManagerKey: DependencyKey {
    public static let liveValue: AuthorizationManager = {
        print("Dependency - 🔐 AuthorizationManagerKey: Starting creation at \(Date())")
        @Dependency(\.healthStore) var healthStore
        print("Dependency - 📦 AuthorizationManagerKey: HealthStore dependency resolved")
        let manager = DefaultAuthorizationManager(healthStore: healthStore)
        print("Dependency - ✅ AuthorizationManagerKey: AuthorizationManager created successfully")
        return manager
    }()
}

public extension DependencyValues {
    var authorizationManager: AuthorizationManager {
        get { self[AuthorizationManagerKey.self] }
        set { self[AuthorizationManagerKey.self] = newValue }
    }
}

/// A TCA dependency key for managing Activity Ring.
public enum ActivityRingManagerKey: DependencyKey {
    public static let liveValue: ActivityRingManager = {
        print("Dependency - 💍 ActivityRingManagerKey: Starting creation at \(Date())")
        @Dependency(\.healthStore) var healthStore
        print("Dependency - 📦 ActivityRingManagerKey: HealthStore dependency resolved")
        let manager = DefaultActivityRingManager(healthStore: healthStore)
        print("Dependency - ✅ ActivityRingManagerKey: ActivityRingManager created successfully")
        return manager
    }()
}

public extension DependencyValues {
    var activityRingManager: ActivityRingManager {
        get { self[ActivityRingManagerKey.self] }
        set { self[ActivityRingManagerKey.self] = newValue }
    }
}

/// A TCA dependency key for accessing a shared instance of HKHealthStore.
public enum HealthStoreKey: DependencyKey {
    public static let liveValue: HKHealthStore = {
        print("Dependency - 🏥 HealthStoreKey: Creating HKHealthStore at \(Date())")
        let healthStore = HKHealthStore()
        print("Dependency - ✅ HealthStoreKey: HKHealthStore created successfully")
        return healthStore
    }()
}

public extension DependencyValues {
    var healthStore: HKHealthStore {
        get { self[HealthStoreKey.self] }
        set { self[HealthStoreKey.self] = newValue }
    }
}


/// A TCA dependency key for accessing the live implementation of the central manager.
public enum CentralManagerKey: DependencyKey {
    public static let liveValue: CentralManager = {
        let centralManager = DefaultCentralManager()
        return centralManager
    }()
}

public extension DependencyValues {
    var centralManager: CentralManager {
        get { self[CentralManagerKey.self] }
        set { self[CentralManagerKey.self] = newValue }
    }
}

/// A TCA dependency key for accessing the live implementation of the watch connectivity manager.
public enum WatchConnectivityManagerKey: DependencyKey {
    public static let liveValue: WatchConnectivityManager = {
        let watchManager = DefaultWatchConnectivityManager()
        return watchManager
    }()
}

public extension DependencyValues {
    var watchConnectivityManager: WatchConnectivityManager {
        get { self[WatchConnectivityManagerKey.self] }
        set { self[WatchConnectivityManagerKey.self] = newValue }
    }
}
