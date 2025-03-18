//
//  SetEditGoalFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 15/02/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct SetEditGoalFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        CombineReducers {
            BindingReducer()
            Reduce { state,action in
                switch action {
                    
                case .binding(_):
                    return .none
                    
                    // MARK: - Actions
                    
                case .validate:
                    guard !state.valueToAdd.isEmpty else {
                        // TODO: - ALERTS
                        print("nie moze byc puste")
                        return .none
                    }
                    
                    dump(state.valueToAdd)
                    
                    return .run { send in
                        await self.dismiss()
                    }
                    
                case let .selectedWeightUnitPickerChange(unit):
                    state.weightUnit = unit
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
                    
                    // MARK: - View Actions
                    
                case .view(.dismissButtonPressed):
                    return .run { send in
                        await self.dismiss()
                    }
                    
                case .view(.saveButtonPressed):
                    return .run { send in
                        await send(.validate)
                    }
                }
            }
        }
    }
    
}
