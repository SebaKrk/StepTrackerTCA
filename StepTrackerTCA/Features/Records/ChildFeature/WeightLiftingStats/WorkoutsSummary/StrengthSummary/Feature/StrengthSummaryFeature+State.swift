//
//  StrengthSummaryFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 08/03/2025.
//

import ComposableArchitecture
import Foundation

/// Represents the state for `StrengthSummaryFeature`
extension StrengthSummaryFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// The fetched workout strength data, if available.
        var data: [WorkoutStrength]?
        
        /// The movement summaries derived from workout strength data.
        var movementSummary: [MovementSummary<StrengthMovement>]?
        
        // MARK: - Destination
        
        /// Represents the navigation destination state within `StrengthSummaryFeature`.
        @Presents var destination: Destination.State?
    }
    
}
