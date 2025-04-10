//
//  SummaryFeature+Destination.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 15/03/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `SummaryFeature` destination
extension SummaryFeature {
    
    @Reducer
    enum Destination {
        
        /// Represents the destination for displaying in `ScoreFeature`.
        case open(ScoresFeature)  
    }
    
}
