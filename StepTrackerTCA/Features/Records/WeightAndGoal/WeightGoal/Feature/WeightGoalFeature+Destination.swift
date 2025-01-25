//
//  WeightGoalFeature+Destination.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 24/01/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `WeightGoalFeature` destination
extension WeightGoalFeature {
    
    @Reducer
    enum Destination {
        
        /// Represents the destination for displaying in `SetWeightGoalFeature`.
        case setWeightGoal(SetWeightGoalFeature)
    }
    
}
