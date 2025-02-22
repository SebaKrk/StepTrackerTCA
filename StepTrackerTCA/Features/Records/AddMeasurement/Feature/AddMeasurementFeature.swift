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
    
    // MARK: - Dependency
    
    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        CombineReducers {
            BindingReducer()
            Reduce { state, action in
                switch action {
                    // MARK: - Actions
                    
                case .validate:
                    guard state.workoutType != nil else {
                        let alertMessage = "Please select a workout type before proceeding."
                        state.alertMessage = alertMessage
                        return .run { send in
                            await send(.presentAlert)
                        }
                    }
                    
                    let isMovementSelected: Bool = {
                        switch state.workoutType {
                        case .weightlifting:
                            return state.weightliftingMovement != nil
                        case .strength:
                            return state.strengthMovement != nil
                        case .fitness:
                            return state.fitnessMovement != nil
                        case .cross:
                            return state.crossMovement != nil
                        case .hero:
                            return state.heroMovement != nil
                        case .none:
                            return false
                        }
                    }()
                    
                    guard isMovementSelected else {
                        let alertMessage = "Please select a movement before proceeding."
                        state.alertMessage = alertMessage
                        return .run { send in
                            await send(.presentAlert)
                        }
                    }
 
                    switch state.workoutType {
                    case .weightlifting, .strength:
                        guard !state.valueToAdd.isEmpty else {
                            let alertMessage = "The value field cannot be empty."
                            state.alertMessage = alertMessage
                            return .run { send in
                                await send(.presentAlert)
                            }
                        }
                    case .fitness, .hero:
                        guard state.timeInterval != 0 else {
                            let alertMessage = "The time value cannot be equal zero."
                            state.alertMessage = alertMessage
                            return .run { send in
                                await send(.presentAlert)
                            }
                        }
                        
                    case .cross:
                        guard !state.crossValueToAdd.isEmpty else {
                            let alertMessage = "The reps value field cannot be empty."
                            state.alertMessage = alertMessage
                            return .run { send in
                                await send(.presentAlert)
                            }
                        }
                    case .none: return .none
                    }
                    
                    return .run { send in
                        await send(.addValue)
                    }
                    
                case .addValue:
                    print("Date: \(state.addDataDate)")
                    switch state.workoutType {
                    case .weightlifting, .strength:
                        print("Save 1 max kg value - \(state.valueToAdd) \(state.weightUnit)")
                    case .fitness, .hero:
                        print("Save time value - \(state.timeInterval)")
                    case .cross:
                        print("Save cross reps value - \(state.crossValueToAdd)")
                    case .none: break
                    }
                    return .run { send in
                        await self.dismiss()
                    }
                    
                    // MARK: - Binding
                case .binding(_):
                    return .none
                    
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
                    
                case .view(.cancelButtonTapped):
                    return .run { send in
                        await self.dismiss()
                    }
                    
                case .view(.addButtonTapped):
                    return .run { send in
                        await send(.validate)
                    }
                    
                    // MARK: - Alert Action
                    
                case .presentAlert:
                    guard let alertMessage = state.alertMessage else { return .none }
                    state.alert = .infoAlert(with: alertMessage)
                    state.alertMessage = nil
                    return .none
                    
                case .alert(.dismiss):
                    state.alert = nil
                    return .none
                    
                case .alert(.presented(_)):
                    return .none
                }
            }
        }
    }
    
}
