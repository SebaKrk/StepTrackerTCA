//
//  WeightBarWidgetFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 17/01/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `WeightDiffWidgetFeature` action
extension WeightDiffWidgetFeature {
    
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
        
        // MARK: - View Actions
        case view(View)
        
        enum View {
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
            
        }
    }
    
}
