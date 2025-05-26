//
//  WorkoutManagerTestKey.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 26/05/2025.
//

import ComposableArchitecture

private enum WorkoutManagerTestKey: DependencyKey {
    static let liveValue: WorkoutManagerTestProtocol = WorkoutManagerTest()
}

extension DependencyValues {
    var workoutManagerTest: WorkoutManagerTestProtocol {
        get { self[WorkoutManagerTestKey.self] }
        set { self[WorkoutManagerTestKey.self] = newValue }
    }
}
