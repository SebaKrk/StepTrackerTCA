//
//  WorkoutFeature+Destination.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 13/05/2025.
//


import ComposableArchitecture
import Foundation

/// Implementation of `WorkoutFeature` destination
extension WorkoutFeature {
    
    @Reducer
    enum Destination {
        
        /// Represents the destination for displaying in `WorkoutFeature`.
        case openImageAnalysis(ImageAnalysisFeature)
        
        /// Represents the destination for displaying in `WorkoutPlanerFeature`.
        case openWorkoutPlaner(WorkoutPlanerFeature)
        
        /// Represents the destination for displaying in `WorkoutMirroringFeature`.
        case openWorkoutMirroring(WorkoutMirroringFeature)
    }
    
}

