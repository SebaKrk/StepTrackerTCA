//
//  SetWeightGoalFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 24/01/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `SetWeightGoalFeature` state
extension SetWeightGoalFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// The date selected for setting the weight goal.
        /// Default value: the current date (`Date.now`).
        var addDataDate: Date = .now
        
        /// The weight goal entered by the user.
        var weightGoal: String = ""
        
    }
}
