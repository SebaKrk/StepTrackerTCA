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
    
    let service = DefaultAddMeasurementServices()
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        CombineReducers {
            BindingReducer()
            Reduce { state, action in
                switch action {
                    // MARK: - Actions
                    
                case .validate:
                    guard let workoutType = state.workoutType else {
                        state.alertMessage = "Please select a workout type before proceeding."
                        return .run { send in await send(.presentAlert) }
                    }

                    let isMovementSelected: Bool = {
                        switch workoutType {
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

                    guard let movement: any MovementType = {
                        switch workoutType {
                        case .weightlifting:
                            return state.weightliftingMovement
                        case .strength:
                            return state.strengthMovement
                        case .fitness:
                            return state.fitnessMovement
                        case .cross:
                            return state.crossMovement
                        case .hero:
                            return state.heroMovement
                        }
                    }() else {
                        state.alertMessage = "Unexpected error: movement is missing."
                        return .run { send in await send(.presentAlert) }
                    }

                    let valueToSave: String

                    switch workoutType {
                    case .weightlifting, .strength:
                        guard !state.valueToAdd.isEmpty else {
                            state.alertMessage = "The value field cannot be empty."
                            return .run { send in await send(.presentAlert) }
                        }
                        valueToSave = state.valueToAdd

                    case .fitness, .hero:
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

                    return .run { send in
                        await send(.addValue(workoutType: workoutType, movement: movement, value: valueToSave))
                    }
                    
                case let .addValue(workoutType, movement, value):
                    let date = state.addDataDate
                    let weightUnit = state.weightUnit

                    return .run { send in
                        do {
                            try await service.saveMeasurement(
                                date: date,
                                workoutType: workoutType,
                                movement: movement,
                                value: value,
                                weightUnit: weightUnit
                            )
                            await self.dismiss()
                        } catch {
                            print("❌ Error saving measurement: \(error.localizedDescription)")
                        }
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
