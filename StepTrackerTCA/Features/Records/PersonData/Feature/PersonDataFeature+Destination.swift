//
//  PersonDataFeature+Destination.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 23/01/2025.
//

import ComposableArchitecture


/// Implementation of `PersonDataFeature` destination
extension PersonDataFeature {
    
    @Reducer
    enum Destination {
        
        /// Represents the destination for displaying in `Tu będzie jakis detailItem`.
        case detailItem
    }
    
}

