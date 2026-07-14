//
//  MovementDetailsFeature+Destination.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 15/04/2025.
//


import ComposableArchitecture

/// Implementation of `MovementDetailsFeature` destination
extension MovementDetailsFeature {
    
    @Reducer
    enum Destination {
        
        /// Represents the destination for displaying in `MovementHistoryFeature`.
        case showMovementHistory(MovementHistoryFeature)
    }
}
