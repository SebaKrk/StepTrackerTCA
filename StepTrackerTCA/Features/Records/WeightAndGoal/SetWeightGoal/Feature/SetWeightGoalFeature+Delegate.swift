//
//  SetWeightGoalFeature+Delegate.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 24/01/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `SetWeightGoalFeature` delegate
extension SetWeightGoalFeature {
    
    /// A delegate enum to handle events related to `SetWeightGoalFeature`.
    enum Delegate: Equatable {
        
        /// Triggered when the user sets a weight goal.
        /// - Parameter weightGoal: An object containing the weight goal data.
        case setGoal(WeightGoal)
    }
    
}
