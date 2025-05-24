//
//  MainFeatureAW+Destination.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 23/05/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `MainFeatureAW` destination
extension MainFeatureAW {
    
    @Reducer
    enum Destination {
        
        /// Represents the destination for displaying in `WorkoutSessionFeature`.
        case workoutSession(WorkoutSessionFeature)
        
        ///
        case openSummary(SummaryFeature)
        
        //case openTest(HeartRateFeature)
    }
    
}
