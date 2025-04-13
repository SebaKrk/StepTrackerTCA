//
//  WorkoutSubmissionStrategyFactoryKey.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 13/04/2025.
//

import ComposableArchitecture

/// A dependency key used to register the default workout submission strategy factory.
///
/// Registers `DefaultWorkoutSubmissionStrategyFactory` as the live value.
private enum WorkoutSubmissionStrategyFactoryKey: DependencyKey {
    static var liveValue: WorkoutSubmissionStrategyFactory = DefaultWorkoutSubmissionStrategyFactory()
}

extension DependencyValues {
    /// Accessor for the workout submission strategy factory dependency.
    ///
    /// Use this property to retrieve or override the default workout submission strategy factory
    /// within a Composable Architecture environment.
    var workoutSubmissionStrategyFactory: WorkoutSubmissionStrategyFactory {
        get { self[WorkoutSubmissionStrategyFactoryKey.self] }
        set { self[WorkoutSubmissionStrategyFactoryKey.self] = newValue }
    }
}
