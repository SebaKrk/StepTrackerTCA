//
//  DashboardFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 21/12/2024.
//

import ComposableArchitecture

/// Implementation of `DashboardFeature` state
extension DashboardFeature {
    
    @ObservableState
    struct State {
        
        /// The currently selected health metric to display on the dashboard.
        /// - Default: `.steps`
        var healthMetric: HealthMetricContext = .steps
        
        ///
        var hasSeenPermissionPriming: Bool = false
        
        ///
        var isShowingPermissionPrimingSheet: Bool = false
        
        // MARK: - Path
        
        /// Path from DashboardFeature
        var path = StackState<Path.State>()
        
        // MARK: - Destination
        
        /// destination from DashboardFeature
        @Presents var destination: Destination.State?
    }
    
}
