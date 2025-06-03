//
//  WorkoutTypeFeature.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 02/06/2025.
//

import ComposableArchitecture
import HealthKit

/// Feature responsible for displaying and handling workout type selection.
@Reducer
struct WorkoutTypeFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            // MARK: - Internal Actions
                
            case let .show(hkType):
                state.destination = .trainingSession(TrainingSessionTabFeature.State(selectedWorkout: hkType))
                return .none
                
            // MARK: - View Actions
            case let .view(.selectedWorkoutType(workoutType)):
                return .send(.show(workoutType.hkType))
                
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
}
