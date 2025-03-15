//
//  SummaryFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 15/03/2025.
//

import ComposableArchitecture
import Foundation
    
    /// Represents the state for `SummaryFeature`
extension SummaryFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// The workout summary containing details of past workouts.
        var data: WorkoutSummary?
        
        /// A collection of grouped workouts categorized by type.
        var groupedWorkouts: [NewGroupedWorkouts]?
        
        // MARK: - Destination
        
        /// Represents the navigation destination state within `SummaryFeature`.
        @Presents var destination: Destination.State?
    }
    
}
