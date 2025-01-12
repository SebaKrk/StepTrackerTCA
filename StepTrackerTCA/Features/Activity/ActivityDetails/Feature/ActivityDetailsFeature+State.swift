//
//  ActivityDetailsFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/01/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `ActivityDetailsFeature` state
extension ActivityDetailsFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// Stores detailed information about a workout.
        var workout: WorkoutData
    }
    
}
