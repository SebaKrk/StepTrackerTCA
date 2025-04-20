//
//  StepWidgetFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 16/01/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `StepWidgetFeature` action
extension StepWidgetFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        /// Action triggered when the user selects a date on the step chart.
        case selectedStepChartDateChange(Date?)
        
        /// Updates the chart data with the given health data set.
        case updateStepChartData([HealthData])
        
        /// Responsible for refreshing dashboard data
        case refresh
        
        // MARK: - View Actions
        case view(View)
        
        enum View {
            
            /// Triggered when navigating to a destination.
            case tapDestination
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
            
        }
        
        // MARK: - Destination
        
        /// Displays detailed information about the data from chart
        case show
        
        /// destination case for navigation
        case destination(PresentationAction<Destination.Action>)
    }
                    
}
