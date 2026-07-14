//
//  PersonDataFeature+Destination.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 18/02/2025.
//

import ComposableArchitecture

/// Implementation of `PersonDataFeature` destination
extension PersonDataFeature {
    
    @Reducer
    enum Destination {
        case show(AddMeasurementFeature)
    }
    
}
