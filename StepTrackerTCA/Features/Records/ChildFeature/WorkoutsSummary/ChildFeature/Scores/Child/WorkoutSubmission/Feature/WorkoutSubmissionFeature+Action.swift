//
//  WorkoutSubmissionFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/04/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `WorkoutSubmissionFeature` action
extension WorkoutSubmissionFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        /// Triggered when the user selects a different weightlifting movement in the picker.
        case selectedWeightliftingMovementPickerChange(WeightliftingMovement?)
        
        /// Triggered when the user selects a different strength movement in the picker.
        case selectedStrengthMovementPickerChange(StrengthMovement?)
        
        /// Triggered when the user selects a different fitness movement in the picker.
        case selectedFitnessMovementPickerChange(FitnessMovement?)
        
        /// Triggered when the user selects a different cross movement in the picker.
        case selectedCrossMovementPickerChange(CrossMovement?)
        
        /// Triggered when the user selects a different hero movement in the picker.
        case selectedHeroMovementPickerChange(HeroMovement?)
        
        /// Triggered when the user selects a different weight unit in the unit picker.
        case selectedWeightUnitPickerChange(WeightUnit)
        
        /// Triggered when the user selects a different workout unit in the picker.
        case selectedWorkoutUnitPickerChange(WorkoutUnit)
        
        ///
        case selectedMomentChange (any MovementType)
        
        /// Validates the measurement inputs.
        case validate
        
        /// This action is responsible for adding a value.
        case addValue
        
        /// Presents an alert in the view.
        case presentAlert
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            /// Triggered when the save button is pressed.
            case saveButtonPressed
            
            /// Triggered when the dismiss button is pressed.
            case dismissButtonPressed
        }
        
        // MARK: - Alert
        
        /// Actions related to alert presentation and handling.
        case alert(PresentationAction<Alert>)
        
        enum Alert: Equatable {
            
            /// Represents a simple informational alert.
            case showMessage
        }
    }
    
}
