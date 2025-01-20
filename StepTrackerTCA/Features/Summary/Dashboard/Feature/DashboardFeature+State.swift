//
//  DashboardFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 21/12/2024.
//

import ComposableArchitecture
import Foundation

/// Implementation of `DashboardFeature` state
extension DashboardFeature {
    
    @ObservableState
    struct State {
        
        /// It is responsible for making sure that certain actions are executed only the first time this view is displayed.
        var isFirstAppearance = true
        
        /// The currently selected health metric to display on the dashboard.
        /// - Default: `.steps`
        var healthMetric: HealthMetricContext = .steps
        
        /// Indicates whether the user has seen the permission priming screen.
        /// This flag is used to determine if the app should display a primer before requesting permissions.
        var hasSeenPermissionPriming: Bool = false
        
        /// The data for steps, used to populate charts and other visualizations on the dashboard.
        var stepData: [HealthData] = []
        
        /// The data for weight data, used to populate charts and other visualizations on the dashboard.
        var weightData: [HealthData] = []
        
        // MARK: - Destination
        
        /// destination from DashboardFeature
        @Presents var destination: Destination.State?
        
        // MARK: - Child actions
        
        /// Stores the information contained in the `StepPieWidgetFeature`
        var stepPieWidget = StepPieWidgetFeature.State()
        
        /// Stores the information contained in the `StepWidgetFeature`
        var stepWidget = StepWidgetFeature.State()
        
        /// Stores the information contained in the `WeightDiffWidgetFeature`
        var weightDiffWidget = WeightDiffWidgetFeature.State()
        
        /// Stores the information contained in the `WeightGoalWidgetFeature`
        var weightGoalWidget = WeightGoalWidgetFeature.State()
        
    }
    
}
