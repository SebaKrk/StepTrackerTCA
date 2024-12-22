//
//  DashboardFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 21/12/2024.
//

import ComposableArchitecture

extension DashboardFeature {
    
    @ObservableState
    struct State: Equatable {
        
        /// The currently selected health metric to display on the dashboard.
        /// - Default: `.steps`
        var healthMetric: HealthMetricContext = .steps
        
    }
    
}
