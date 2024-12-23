//
//  AddMetricDataFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 23/12/2024.
//

import ComposableArchitecture
import Foundation

/// Implementation of `AddMetricDataFeature` action
extension AddMetricDataFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            /// Action triggered when the "Add Data" button is pressed.
            case addDataButtonPressed
            
            /// Action triggered when the "Dismiss" button is pressed.
            case dismissButtonPressed
        }
    }
    
}
