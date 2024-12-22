//
//  HealthDataListFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 22/12/2024.
//

import ComposableArchitecture

/// Implementation of `HealthDataListFeature` state
extension HealthDataListFeature {
    
    @ObservableState
    struct State: Equatable {
        
        /// This value represents the health metric to display
        var healthMetric: HealthMetricContext
        
    }
    
}
