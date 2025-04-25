//
//  WorkoutFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/01/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct WorkoutFeature {
    
    let service = DefaultWorkoutService()
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        CombineReducers {
            BindingReducer()
            Reduce { state, action in
                switch action {
                    // MARK: - Actions
                    
                case .binding(_):
                    return .none
                    
                case .save:
                    return .run { [date = state.addDataDate, value = state.value] send in
                        if let weight = Double(value) {
                            try await service.setWeightGoal(weight, date: date)
                            await send(.clearAndReload)
                        } else {
                            print("❌ Błąd konwersji: \(value) nie jest poprawną liczbą")
                        }
                    }
                    
                case .clearAndReload:
                    state.value = ""
                    return .run { send in
                        if let goal = try? await service.fetchWeightGoal() {
                            await send(.updateCurrentWeight(goal))
                        } else {
                            print("⚠️ Brak ustawionego celu – goal jest nil")
                        }
                    }
                    
                case let .updateCurrentWeight(goal):
                    state.weightGoal = goal
                    return .none
                    
                    // MARK: - View Actions
                    
                case .view(.saveGoalButtonPressed):
                    return .run { send in
                        await send(.save)
                    }
                    
                case .view(.viewDidAppear):
                    return .run { send in
                        if let goal = try await service.fetchWeightGoal() {
                            await send(.updateCurrentWeight(goal))
                        }
                    }
                }
            }
        }
    }
    
}
