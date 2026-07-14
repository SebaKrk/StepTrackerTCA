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
            
        /// The type of workout that is currently being tracked or displayed.
        var selectedWorkoutType: WorkoutType
        
        /// The summary data containing the details of the workout session.
        /// This includes performance metrics, goals, and other relevant information.
        /// It is `nil` if no summary data is available.
        var summary: Summary? = nil
        
        /// The currently selected movement within the grouped movements.
        /// This property represents the movement actively being tracked or evaluated.
        /// It is `nil` if no movement is currently selected.
        var selectedMovement: GroupedMovement? = nil
        
        /// An array of filtered movements derived from the summary data.
        /// These movements are filtered based on specific criteria or user selections.
        var filteredMovements: [FilteredMovement] = []
        
        // MARK: - Destination
        
        /// Represents the navigation destination state within `SummaryFeature`.
        /// This property handles transitions to different screens or modals within the feature.
        @Presents var destination: Destination.State?
    }
    
}
