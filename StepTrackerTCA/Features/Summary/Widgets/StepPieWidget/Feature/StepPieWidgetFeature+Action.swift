//
//  StepPieWidgetFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 16/01/2025.
//

import ComposableArchitecture
import Foundation


/// Implementation of `StepPieWidgetFeature` action
extension StepPieWidgetFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        /// Handles changes to the raw value of the selected chart data.
        case rawSelectedChartValueChange(Double?)
        
        /// Updates the chart data with the given health data set.
        case updatePieChartData([HealthData])
  
        // MARK: - View Actions
        case view(View)
        
        enum View {
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
            
        }
    }
                    
}
