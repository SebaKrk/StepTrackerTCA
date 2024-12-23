//
//  HealthDataListFeature+Destination.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 23/12/2024.
//

import ComposableArchitecture
import Foundation

/// Implementation of `HealthDataListFeature` destination
extension HealthDataListFeature {
    
    @Reducer(state: .equatable)
    enum Destination {
        case openAddMetricData(AddMetricDataFeature)
    }
    
}
