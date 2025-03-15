//
//  SetEditGoalFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 15/02/2025.
//


import ComposableArchitecture
import Foundation

/// Implementation of `SetEditGoalFeature` action
extension SetEditGoalFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        /// Triggered when the user selects a different movement type in the movement picker.
        case selectedMovementPickerChange(WeightliftingMovement?)
        
        /// Triggered when the user selects a different weight unit in the unit picker.
        case selectedWeightUnitPickerChange(WeightUnit)
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            /// Triggered when the save button is pressed.
            case saveButtonPressed
            
            /// Triggered when the dismiss button is pressed.
            case dismissButtonPressed
        }
    }
    
}
