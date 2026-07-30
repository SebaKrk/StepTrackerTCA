//
//  ActivityFeature+Destination.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/01/2025.
//

import ComposableArchitecture

/// Implementation of `ActivityFeature` destination
extension ActivityFeature {
    
    @Reducer
    enum Destination {
        
        /// Represents the destination for displaying in `ActivityDetailsFeature`.
        case detailItem(ActivityDetailsFeature)
        
        ///
        case heartRateDetails(HeartRateDetailsFeature)
    }
}
