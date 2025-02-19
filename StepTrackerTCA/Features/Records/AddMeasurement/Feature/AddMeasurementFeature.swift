//
//  AddMeasurementFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 18/02/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct AddMeasurementFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
            case .binding(_):
                return .none
                
                // MARK: - Actions
                
            case let .selectedWorkoutPickerChange(type):
                state.workoutType = type
                return .none
                
            case let .selectedWeightliftingMovementPickerChange(movement):
                state.weightliftingMovement = movement
                return .none
                
            case let .selectedStrengthMovementPickerChange(movement):
                state.strengthMovement = movement
                return .none
                
            case let .selectedFitnessMovementPickerChange(movement):
                state.fitnessMovement = movement
                return .none
            case let .selectedCrossMovementPickerChange(movement):
                state.crossMovement = movement
                return .none
                
            case let .selectedHeroMovementPickerChange(movement):
                state.heroMovement = movement
                return .none
                
            case let .selectedWeightUnitPickerChange(unit):
                state.weightUnit = unit
                return .none
                
            case let .selectedWorkoutUnitPickerChange(unit):
                state.workoutUnit = unit
                return .none
                
                // MARK: - View Actions
                
            case .view(.viewDidAppear):
                return .none
            }
        }
    }
    
}

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


import ComposableArchitecture
import Foundation

/// Implementation of `AddMeasurementFeature` state
extension AddMeasurementFeature {
    
    @ObservableState
    struct State: Equatable {
        
        // MARK: - Properties
        
        /// The date for which the user wants to add  data.
        /// Defaults to the current date.
        var addDataDate: Date = .now
        
        ///
        var selectedTime: Date = .now
        
        ///
        var workoutType: WorkoutType? = nil
        
        ///
        var weightliftingMovement: WeightliftingMovement? = nil
        
        ///
        var strengthMovement: StrengthMovement? = nil
        
        ///
        var fitnessMovement: FitnessMovement? = nil
        
        ///
        var crossMovement: CrossMovement? = nil
        
        ///
        var heroMovement: HeroMovement? = nil
        
        /// The value to add, entered as a string.
        var valueToAdd: String = ""
        
        /// The selected unit of measurement for weight.
        var weightUnit: WeightUnit = .kg
        
        ///
        var workoutUnit: WorkoutUnit = .reps
        
    }
    
}
