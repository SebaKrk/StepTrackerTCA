//
//  WeightLiftingStatsFeature+Destination.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 08/02/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `WeightLiftingStatsFeature` destination
extension WeightLiftingStatsFeature {
    
    @Reducer
    enum Destination {
        
        /// Represents the destination for displaying in `WeightLiftingGoalsFeature`.
        case open(WeightLiftingGoalsFeature)
    }
    
}
