//
//  WorkoutManagerTestKey.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 28/05/2025.
//

import ComposableArchitecture
import HealthKit

private enum TrainingManagerKey: DependencyKey {
    static let liveValue: TrainingManager = DefaultTrainingManager()
}

extension DependencyValues {
    var trainingManager: TrainingManager {
        get { self[TrainingManagerKey.self] }
        set { self[TrainingManagerKey.self] = newValue }
    }
}

