//
//  SetWeightGoalFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 24/01/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `SetWeightGoalFeature` action - defines actions related to setting a weight goal.
extension SetWeightGoalFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Action
        
        /// Validates the entered weight goal before saving.
        case validate
        
        /// Saves the weight goal.
        case save
        
        /// Triggered when the user selects a different weight unit in the picker.
        case selectedWeightUnitPickerChange(WeightUnit)
        
        /// Presents an alert in the view.
        case presentAlert
        
        /// Presents an alert when saving the weight goal fails.
        case presentSaveFailedAlert(Error)
        
        // MARK: View Action
        
        /// Represents actions triggered by the user from the UI.
        case view(View)
        
        enum View {
            
            /// Triggered when the "Save Goal" button is pressed.
            case saveGoalButtonPressed
            
            /// Triggered when the "Dismiss" button is pressed.
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
