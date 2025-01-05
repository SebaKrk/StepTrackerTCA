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
        
        /// Indicates whether the user has seen the permission priming screen.
        /// This flag is used to determine if the app should display a primer before requesting permissions.
        var hasSeenPermissionPriming: Bool = false
        
        /// The data for steps, used to populate charts and other visualizations on the dashboard.
        var stepData: [HealthData] = []
        
        /// The average step count calculated from `stepData`.
        /// This value is derived to provide quick insights to the user, such as the average number of steps taken over a days
        var avgStepCount: Double = 0
        
        // MARK: - Path
        
        /// Path from DashboardFeature
        var path = StackState<Path.State>()
        
        // MARK: - Destination
        
        /// destination from DashboardFeature
        @Presents var destination: Destination.State?
    }
    
}
