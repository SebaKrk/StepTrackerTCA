//
//  AddMeasurementFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 19/02/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of the `AddMeasurementFeature` actions.
extension AddMeasurementFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        /// Triggered when the user selects a different workout type in the movement picker.
        case selectedWorkoutPickerChange(WorkoutType?)
      
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
        
        /// Triggered when the user selects a different weight unit in the picker.
        case selectedWeightUnitPickerChange(WeightUnit)
        
        /// Triggered when the user selects a different workout unit in the picker.
        case selectedWorkoutUnitPickerChange(WorkoutUnit)
        
        /// Validates the measurement inputs.
        case validate
        
        /// Adds a measurement value.
        /// This action is triggered after validation, meaning all required values are guaranteed to be non-nil.
        //case addValue(workoutType: WorkoutType, movement: any MovementType, value: String, unit: String)
        case addValue
        
        /// Presents an alert in the view.
        case presentAlert
        
        // MARK: - View Actions
        
        /// Handles actions originating from the view.
        case view(View)
        
        enum View {
            
            /// Notifies that the view has appeared.
            case viewDidAppear
            
            /// Triggered when the add button is tapped.
            case addButtonTapped
            
            /// Triggered when the cancel button is tapped.
            case cancelButtonTapped
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
