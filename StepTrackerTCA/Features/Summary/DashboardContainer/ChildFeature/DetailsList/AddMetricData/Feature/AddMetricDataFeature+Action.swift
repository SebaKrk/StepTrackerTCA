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
        
        /// Presents an alert in the view.
        case presentAlert
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            /// Action triggered when the "Add Data" button is pressed.
            case addDataButtonPressed
            
            /// Action triggered when the "Dismiss" button is pressed.
            case dismissButtonPressed
        }
        
        // MARK: - Alert
        
        /// Actions related to alert presentation and handling.
        case alert(PresentationAction<Alert>)
        
        enum Alert: Equatable {
            
            /// Represents a simple informational alert.
            case showMessage
        }
        
        // MARK: - Delegate
        /// Actions to communicate with parent features or modules.
        case delegate(Delegate)
        
    }
    
}
