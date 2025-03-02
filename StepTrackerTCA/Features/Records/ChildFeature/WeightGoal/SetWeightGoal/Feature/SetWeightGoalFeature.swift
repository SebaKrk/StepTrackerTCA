//
//  SetWeightGoalFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 24/01/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct SetWeightGoalFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.dismiss) var dismiss
    
    let setWeightGoalService = DefaultSetWeightGoalService()
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        CombineReducers {
            BindingReducer()
            Reduce { state, action in
                switch action {
                    
                    // MARK: - Binding
                case .binding(_):
                    return .none
                    
                case let .selectedWeightUnitPickerChange(unit):
                    state.weightUnit = unit
                    return .none
                    
                    // MARK: - Action
                    
                case .validate:
                    guard !state.value.isEmpty else {
                        let alertMessage = "Weight value cannot be empty"
                        state.alertMessage = alertMessage
                        return .run { send in
                            await send(.presentAlert)
                        }
                    }
                    return .run { send in
                        await send(.save)
                    }
                    
                    case .save:
                    return .run { [date = state.addDataDate, goal = state.value, unit = state.weightUnit] send in
                        if let weightGoal = Double(goal) {
                            do {
                                let goal = WeightGoal(id: UUID().uuidString,
                                                      weight: weightGoal,
                                                      weightUnit: unit,
                                                      dateAdded: date)
                                
                                try await setWeightGoalService.setWeightGoal(goal)
                                await send(.delegate(.setGoal(goal)))
                                await self.dismiss()
                            } catch {
                                await send(.presentSaveFailedAlert(error))
                            }
                        }
                    }
                    
                    // MARK: - View Action
                    
                case .view(.saveGoalButtonPressed):
                    return .run { send in
                        await send(.validate)
                    }
                
                case .view(.dismissButtonPressed):
                    return .run { send in
                        await self.dismiss()
                    }
                    
                    // MARK: - Alert actions
                case .presentAlert:
                    guard let alertMessage = state.alertMessage else { return .none }
                    state.alert = .infoAlert(with: alertMessage)
                    state.alertMessage = nil
                    return .none
                
                case let .presentSaveFailedAlert(error):
                    state.alert = .infoAlert(with: "Failed to save weight goal. Please try again later.")
                    print("❌ Failed to save weight goal: \(error.localizedDescription)")
                    state.alertMessage = nil
                    return .none
                    
                case .alert(.dismiss):
                    state.alert = nil
                    return .none
                    
                default: return .none
                }
            }
        }
    }
}
