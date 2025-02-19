//
//  AddMeasurementFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 19/02/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `AddMeasurementFeature` action
extension AddMeasurementFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        /// Triggered when the user selects a different workout type in the movement picker.
        case selectedWorkoutPickerChange(WorkoutType?)
      
        ///
        case selectedWeightliftingMovementPickerChange(WeightliftingMovement?)
        
        ///
        case selectedStrengthMovementPickerChange(StrengthMovement?)
        
        ///
        case selectedFitnessMovementPickerChange(FitnessMovement?)
        
        ///
        case selectedCrossMovementPickerChange(CrossMovement?)
        
        ///
        case selectedHeroMovementPickerChange(HeroMovement?)
        
        ///
        case selectedWeightUnitPickerChange(WeightUnit)
        
        ///
        case selectedWorkoutUnitPickerChange(WorkoutUnit)
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            case viewDidAppear
        }
    }
    
}
