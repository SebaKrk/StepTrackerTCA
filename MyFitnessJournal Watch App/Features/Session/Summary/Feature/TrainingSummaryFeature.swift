//
//  TrainingSummaryFeature.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 30/05/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct TrainingSummaryFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.trainingSummaryClient) var client
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        CombineReducers {
            BindingReducer()
            Reduce { state, action in
                switch action {
                    
                    // MARK: - Binding
                case .binding(_):
                    return .none
                    
                    // MARK: - Actions
                    
                case let .changeViewState(viewState):
                    state.viewState = viewState
                    return .none
                    
                case .changeSummaryState:
                    client.setShowingSummary(false)
                    return .none

                case .checkWorkoutSummary:
                    state.summary = client.getWorkoutSummary()
                    state.retryCount = 0
                    
                    if state.summary?.workout != nil {
                        return .send(.changeViewState(.successfullyLoaded))
                    }
                    return .send(.retryWorkoutCheck)
                    
                case .retryWorkoutCheck:
                    guard state.retryCount < 10 else {
                        return .send(.changeViewState(.failed))
                    }
                    
                    state.retryCount += 1
                    
                    return .run { send in
                        try await Task.sleep(for: .seconds(1))
                        await send(.performWorkoutCheck)
                    }
                    
                case .performWorkoutCheck:
                    state.summary = client.getWorkoutSummary()
                    if state.summary?.workout != nil {
                        return .send(.changeViewState(.successfullyLoaded))
                    }
                    return .send(.retryWorkoutCheck)
                    
                    // MARK: - View Actions
                case .view(.doneButtonPressed):
                    return .run { send in
                        await send(.changeSummaryState)
                        await self.dismiss()
                    }
                    
                case .view(.viewDidAppear):
                    return .send(.checkWorkoutSummary)
                }
            }
        }
    }
    
}
