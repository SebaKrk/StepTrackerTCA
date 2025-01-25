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
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        CombineReducers {
            BindingReducer()
            Reduce { state, action in
                switch action {
                    
                    // MARK: - Binding
                case .binding:
                    return .none
                    
                    // MARK: - View Action
                case .view(.saveGoalButtonPressed):
                    return .run { [ date = state.addDataDate, value = state.weightGoal ] send in
                        await send(.delegate(.setGoal(HealthData(date: date, value: Double(value) ?? 0))))
                        await self.dismiss()
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
