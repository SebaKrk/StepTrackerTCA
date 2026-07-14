//
//  ScoresFeatureServicesKey.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 10/04/2025.
//

import ComposableArchitecture
import Foundation

private enum ScoresFeatureServicesKey: DependencyKey {
    static let liveValue: ScoresFeatureServices = DefaultScoresFeatureServices(strategy: { workoutType in
        switch workoutType {
        case .cross, .fitness, .hero, .strength, .weightlifting:
            return SingleWorkoutStrategy(workoutType: workoutType)
        }
    })
}

extension DependencyValues {
    
    var scoresFeatureServices: ScoresFeatureServices {
        get { self[ScoresFeatureServicesKey.self] }
        set { self[ScoresFeatureServicesKey.self] = newValue }
    }
    
}
