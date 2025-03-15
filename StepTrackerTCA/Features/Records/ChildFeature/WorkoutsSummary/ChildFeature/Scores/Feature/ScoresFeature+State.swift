//
//  ScoresFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 15/03/2025.
//

import ComposableArchitecture
import Foundation

/// Represents the state for `ScoresFeature`
extension ScoresFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// The currently selected workout session, grouped by type or date.
        var selectedWorkout: NewGroupedWorkouts
        
        /// The best workout session based on evaluation criteria, if available.
        var bestResult: (any WorkoutSessionProtocol)?
        
        // MARK: - Destination
        
        /// Represents the navigation destination state within `SummaryFeature`.
        @Presents var destination: Destination.State?
    }
    
}
