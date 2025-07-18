//
//  WorkoutCreatorFeature+Destination.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 12/07/2025.
//

import ComposableArchitecture

/// Implementation of `WorkoutCreatorFeature` destination
extension WorkoutCreatorFeature {
    
    @Reducer
    enum Destination {
        
        /// Represents the destination for displaying in `WodCreatorFeature`.
        case openWodCreator(WodCreatorFeature)
        
        /// Represents the destination for displaying in `WorkoutPreviewFeature`.
        case openWorkoutPreview(WorkoutPreviewFeature)
        
        case openWorkoutActivityType(WorkoutActivityTypeFeature)
    }
    
}
