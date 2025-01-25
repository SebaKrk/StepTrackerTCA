//
//  SetWeightGoalFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 24/01/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `SetWeightGoalFeature` action
extension SetWeightGoalFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: View Action
        
        case view(View)
        
        enum View {
            
            /// Triggered when the "Save Goal" button is pressed.
            case saveGoalButtonPressed
            
            /// Triggered when the "Dismiss" button is pressed.
            case dismissButtonPressed
        }
        
        // MARK: - Delegate
        
        /// Actions to communicate with parent features or modules.
        case delegate(Delegate)
    }
    
}
