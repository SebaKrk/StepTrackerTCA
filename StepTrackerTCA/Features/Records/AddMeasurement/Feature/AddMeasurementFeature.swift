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
