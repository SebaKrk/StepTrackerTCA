//
//  WorkoutTypeFeature+Destination.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 03/06/2025.
//

import ComposableArchitecture

/// Implementation of `WorkoutTypeFeature` destination
extension WorkoutTypeFeature {
    
    @Reducer
    enum Destination {
        
        /// Represents the destination for displaying in `TrainingSessionTabFeature`.
        case trainingSession(TrainingSessionTabFeature)
    }
    
}
