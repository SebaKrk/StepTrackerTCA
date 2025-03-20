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
    
    let service: SetEditGoalService
    
    // MARK: - Lifecycle
    
    init(_ service: SetEditGoalService = DefaultSetEditGoalService()) {
        self.service = service
    }
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        CombineReducers {
            BindingReducer()
            Reduce {
                state,
                action in
                switch action {
                    
                case .binding(_):
                    return .none
                    
                    // MARK: - Actions
                    
                case .validate:
                    
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
                        }
                    }()
                    
                    guard isMovementSelected else {
                        state.alertMessage = "Please select a movement before proceeding."
                        return .run { send in await send(.presentAlert) }
                    }
                    
                    let valueToSave: String
                    
                    switch state.workoutType {
                    case .weightlifting,
                            .strength:
                        guard !state.valueToAdd.isEmpty else {
                            state.alertMessage = "The value field cannot be empty."
                            return .run { send in await send(.presentAlert) }
                        }
                        valueToSave = state.valueToAdd
                        
                    case .fitness,
                            .hero:
                        guard state.timeInterval != 0 else {
                            state.alertMessage = "The time value cannot be equal zero."
                            return .run { send in await send(.presentAlert) }
                        }
                        valueToSave = "\(state.timeInterval)"
                        
                    case .cross:
                        guard !state.crossValueToAdd.isEmpty else {
                            state.alertMessage = "The reps value field cannot be empty."
                            return .run { send in await send(.presentAlert) }
                        }
                        valueToSave = state.crossValueToAdd
                    }
                    
                    state.valueToAdd = valueToSave
                    
                    return .run { send in
                        await send(.addValue)
                    }
                    
                case .addValue:
                    
                    return .run { [workout = state.workoutType,
                                   movement = state.selectedMovement,
                                   date = state.addDataDate,
                                   value = state.valueToAdd] send in
                        
                        service.setNewGoal(for: workout, movement,
                                           date: date,
                                           value: value
                        )
                        await self.dismiss()
                    }
                    
                case let .selectedWeightUnitPickerChange(unit):
                    state.weightUnit = unit
                    return .none
                    
                case let .selectedWorkoutUnitPickerChange(unit):
                    state.workoutUnit = unit
                    return .none
                    
                case let .selectedWeightliftingMovementPickerChange(movement):
                    state.weightliftingMovement = movement
                    
                    return .run { send in
                        guard let movement = movement else { return }
                        await send(.selectedMomentChange(movement))
                    }
                    
                case let .selectedStrengthMovementPickerChange(movement):
                    state.strengthMovement = movement
                    return .run { send in
                        guard let movement = movement else { return }
                        await send(.selectedMomentChange(movement))
                    }
                    
                case let .selectedFitnessMovementPickerChange(movement):
                    state.fitnessMovement = movement
                    return .run { send in
                        guard let movement = movement else { return }
                        await send(.selectedMomentChange(movement))
                    }
                    
                case let .selectedCrossMovementPickerChange(movement):
                    state.crossMovement = movement
                    return .run { send in
                        guard let movement = movement else { return }
                        await send(.selectedMomentChange(movement))
                    }
                    
                case let .selectedHeroMovementPickerChange(movement):
                    state.heroMovement = movement
                    return .run { send in
                        guard let movement = movement else { return }
                        await send(.selectedMomentChange(movement))
                    }
                    
                case let .selectedMomentChange(movement):
                    state.selectedMovement = movement
                    return .run { send in
                        await send(.selectedMomentChange(movement))
                    }
                    
                    // MARK: - View Actions
                    
                case .view(.dismissButtonPressed):
                    return .run { send in
                        await self.dismiss()
                    }
                    
                case .view(.saveButtonPressed):
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
