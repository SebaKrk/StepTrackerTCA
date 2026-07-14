//
//  DashboardFeature+Destination.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 30/12/2024.
//

import ComposableArchitecture

/// Implementation of `DashboardFeature` destination
extension DashboardFeature {
    
    @Reducer(state: .equatable)
    enum Destination {
        case openHealthKitPermissionScreen(HealthKitPermissionFeature)
    }
    
}
