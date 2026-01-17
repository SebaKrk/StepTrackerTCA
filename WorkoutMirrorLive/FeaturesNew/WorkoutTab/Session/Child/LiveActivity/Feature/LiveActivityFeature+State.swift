//
//  LiveActivityFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 17/01/2026.
//

import ComposableArchitecture
import SharedModels

/// Implementation of `LiveActivityFeature` action
extension LiveActivityFeature {
    
    @ObservableState
    struct State: Equatable {
        
        /// Maps Live Activity types to their active IDs
        /// Example: [.workout: "ABC-123-DEF"]
        var activeActivities: [LiveActivityType: String] = [:]
        
        /// Convenience: Check if workout Live Activity is active
        var isWorkoutActive: Bool {
            activeActivities[.workout] != nil
        }
    }
    
}
