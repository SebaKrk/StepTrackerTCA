//
//  StepWidgetFeature+Destination.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 17/01/2025.
//

import ComposableArchitecture

/// Implementation of `StepWidgetFeature` destination
extension StepWidgetFeature {
    
    @Reducer(state: .equatable)
    enum Destination {
        case detailList(HealthDataListFeature)
    }
    
}
