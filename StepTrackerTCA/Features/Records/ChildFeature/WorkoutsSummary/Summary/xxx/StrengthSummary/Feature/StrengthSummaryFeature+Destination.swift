//
//  StrengthSummaryFeature+Destination.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 08/03/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `StrengthSummaryFeature` destination
extension StrengthSummaryFeature {
    
    @Reducer
    enum Destination {
        
        /// Represents the destination for displaying in `StrengthScoreFeature`.
        case open(StrengthScoreFeature)
    }
    
}
