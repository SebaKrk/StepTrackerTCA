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
                    
//                case let .selectedMovementPickerChange(movement):
//                    state.movementType = movement
//                    return .none
                case let .selectedMovementChange(movement):
                    print(movement)
                    return .none
                    
                case let .selectedWeightUnitPickerChange(unit):
                    state.weightUnit = unit
                    return .none
                    
                    // MARK: - View Actions
                    
                case .view(.dismissButtonPressed):
                    return .run { send in
                        await self.dismiss()
                    }
                    
                case .view(.saveButtonPressed):
                    print("save button pressed")
                    return .none

                }
            }
        }
    }
    
}
