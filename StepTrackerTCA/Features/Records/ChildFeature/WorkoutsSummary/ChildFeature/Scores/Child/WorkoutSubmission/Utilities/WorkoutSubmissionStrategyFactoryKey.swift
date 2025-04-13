//
//  WorkoutSubmissionStrategyFactoryKey.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 13/04/2025.
//

import ComposableArchitecture

// DependencyKey
private enum WorkoutSubmissionStrategyFactoryKey: DependencyKey {
    static var liveValue: WorkoutSubmissionStrategyFactory = DefaultWorkoutSubmissionStrategyFactory()
}

extension DependencyValues {
    var workoutSubmissionStrategyFactory: WorkoutSubmissionStrategyFactory {
        get { self[WorkoutSubmissionStrategyFactoryKey.self] }
        set { self[WorkoutSubmissionStrategyFactoryKey.self] = newValue }
    }
}

