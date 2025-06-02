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
                    print("🔍 checkWorkoutSummary called at: \(Date())")
                    state.summary = client.getWorkoutSummary()
                    state.retryCount = 0
                    print("🔍 Initial summary workout is: \(state.summary?.workout != nil ? "SUCCESS" : "NIL")")
                    
                    if state.summary?.workout != nil {
                        print("✅ Workout ready immediately - showing loaded state")
                        return .send(.changeViewState(.successfullyLoaded))
                    }
                    
                    print("⏳ Workout not ready - starting retry sequence")
                    return .send(.retryWorkoutCheck)
                    
                case .retryWorkoutCheck:
                    print("🔄 retryWorkoutCheck - attempt \(state.retryCount + 1)/10")
                    guard state.retryCount < 10 else {
                        print("❌ Maximum retries reached (10) - setting failed state")
                        return .send(.changeViewState(.failed))
                    }
                    
                    state.retryCount += 1
                    print("⏱️ Waiting 500ms before next check (attempt \(state.retryCount))")
                    
                    return .run { send in
                        try await Task.sleep(for: .seconds(1))
                        print("⏰ Sleep completed - performing workout check")
                        await send(.performWorkoutCheck)
                    }
                    
                case .performWorkoutCheck:
                    print("🔍 performWorkoutCheck - attempt \(state.retryCount)")
                    state.summary = client.getWorkoutSummary()
                    print("🔍 Summary workout is: \(state.summary?.workout != nil ? "SUCCESS" : "NIL")")
                    
                    if state.summary?.workout != nil {
                        print("✅ Workout ready on attempt \(state.retryCount) - showing loaded state")
                        return .send(.changeViewState(.successfullyLoaded))
                    }
                    
                    print("⏳ Workout still not ready - scheduling next retry")
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
