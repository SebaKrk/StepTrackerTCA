//
//  SetEditGoalFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 15/02/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `SetEditGoalFeature` state
extension SetEditGoalFeature {
    
    @ObservableState
    struct State: Equatable {
        
        // MARK: - Properties
        
        /// The date for which the user wants to add  data.
        /// Defaults to the current date.
        var addDataDate: Date = .now
        
        /// The selected movement type for the goal.
        ///
        /// If `nil`, no movement type has been selected yet.
        var movementType: WeightliftingMovement? = nil
        
        /// The selected unit of measurement for weight.
        var weightUnit: WeightUnit = .kg
        
        /// The value to add, entered as a string.
        var valueToAdd: String = ""
        
    }
    
}
