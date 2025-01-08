//
//  DashboardFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 21/12/2024.
//

import ComposableArchitecture
import Foundation

/// Implementation of `DashboardFeature` action
extension DashboardFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        case changeIsFirstAppearance
        
        /// Action triggered when the user changes the picker selection.
        ///
        /// - Parameter: `HealthMetricContext` representing the selected metric.
        case selectedPickerChange(HealthMetricContext)
        
        /// Triggers the fetching of health data.
        /// This action starts the process of retrieving health-related metrics from an external source.
        case fetchHealthData
        
        /// Updates the step chart data with the result of a health data fetch.
        ///
        /// - Parameter result: A `Result` containing an array of `HealthData` on success
        /// or an `Error` on failure.
        case updateStepChartData(Result<[HealthData], Error>)
        
        /// Action triggered when the user selects a date on the step chart.
        case selectedStepChartDateChange(Date?)
        
        /// Handles changes to the raw value of the selected chart data.
        case rawSelectedChartValueChange(Double?)
        
        // MARK: - Path
        
        /// Path
        case path(StackActionOf<Path>)
        
        // MARK: - Destination
        
        /// Trigger this action when the user needs to review or modify app permissions.
        case openPermissionScreen
        
        /// destination case for navigation
        case destination(PresentationAction<Destination.Action>)
        
        // MARK: - View actions
        
        /// Used for view actions.
        case view(View)
        
        enum View {
                        
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
        }
    }
    
}
