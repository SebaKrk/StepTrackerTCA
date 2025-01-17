//
//  WeightGoalWidgetFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 16/01/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `WeightGoalWidgetFeature` action
extension WeightGoalWidgetFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        /// Updates the chart data with the given health data set.
        case updateWeightChartData([HealthData])
        
        // MARK: - View Actions
        
        case view(View)
        
        /// Action triggered when the user selects a date on the chart.
        case selectedChartDateChange(Date?)
        
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
