//
//  WeightLiftingGoalsFeature+Destination.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 08/02/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `WeightLiftingGoalsFeature` destination
extension WeightLiftingGoalsFeature {
    
    @Reducer
    enum Destination {
        
        /// Represents the destination for displaying in `Tu dać feature`.
        case open(SetWeightGoalFeature)
    }
    
}

