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
                case .binding:
                    return .none
                    
                    // MARK: - Action
                case let .save(currentWeight):
                    return .run { send in
                        do {
                            try await setWeightGoalService.setWeightGoal(currentWeight.value, date: currentWeight.date)
                            await self.dismiss()
                        } catch {
                            // TODO: - Alert
                            print("❌ Failed to set weight goal: \(error.localizedDescription)")
                        }
                    }
                    
                    // MARK: - View Action
                case .view(.saveGoalButtonPressed):
                    return .run { [ date = state.addDataDate, value = state.weightGoal ] send in
                        await send(.save(HealthData(date: date, value: Double(value) ?? 0)))
                        //await send(.delegate(.setGoal(HealthData(date: date, value: Double(value) ?? 0))))
                    }
                               
                case .view(.dismissButtonPressed):
                    return .run { send in
                        await self.dismiss()
                    }
                    
                default: return .none
                }
            }
        }
    }
}
