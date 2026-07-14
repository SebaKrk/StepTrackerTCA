//
//  CurrentWeightFeature+Destination.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 26/01/2025.
//

import ComposableArchitecture

/// Implementation of `CurrentWeightFeature` destination
extension CurrentWeightFeature {
    
    @Reducer(state: .equatable)
    enum Destination {
        case openHealthKitPermissionScreen(HealthKitPermissionFeature)
    }
    
}
