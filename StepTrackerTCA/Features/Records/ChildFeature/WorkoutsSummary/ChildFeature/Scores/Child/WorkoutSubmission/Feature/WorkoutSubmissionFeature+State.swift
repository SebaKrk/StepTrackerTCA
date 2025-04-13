//
//  WorkoutSubmissionFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/04/2025.
//

import ComposableArchitecture

/// Implementation of `SetEditGoalFeature` state
extension WorkoutSubmissionFeature {
    
    @ObservableState
    struct State {
        
        var service: Service
        var workoutType: WorkoutType
    }
}
