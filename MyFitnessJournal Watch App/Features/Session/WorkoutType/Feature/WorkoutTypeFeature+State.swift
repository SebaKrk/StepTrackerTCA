//
//  SWorkoutTypeFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 03/06/2025.
//

import ComposableArchitecture
import SharedModels

/// Implementation of `WorkoutTypeFeature` state
extension WorkoutTypeFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        ///
        var workoutTypes: [WorkoutType] = [.boxing, .cross, .functional, .strength]
        
        // MARK: - Destination
        
        /// destination from MovementDetailsFeature
        @Presents var destination: Destination.State?
    }
    
}
