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
        
        /// Action triggered when the user selects a date on the chart.
        case selectedChartDateChange(Date?)
        
        /// Responsible for refreshing dashboard data
        case refresh
        
        /// Action triggered to fetch the current weight goal from the storage or service.
        ///
        /// This is typically dispatched to retrieve the user's existing weight goal when the feature is initialized.
        case fetchWeightGoal
        
        /// Action triggered to set or update the weight goal.
        ///
        /// This is used to store or adjust the user's weight goal in the storage or service with the provided value.
        /// - Parameter: The new weight goal value as a `Double`.
        case setWeightGoal(Double)
        
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
