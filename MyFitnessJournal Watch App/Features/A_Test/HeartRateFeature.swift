//
//  HeartRateFeature.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 24/05/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct HeartRateFeature {
    
    @Dependency(\.healthKitClient) var healthKitClient
    
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
                case let .heartRateUpdated(bpm):
                    state.heartRate = Int(bpm)
                    return .none
                    // MARK: - View Actions
                case .view(.startWorkout):
                    return .run { send in
                        await healthKitClient.start { bpm in
                            await send(.heartRateUpdated(bpm))
                        }
                    }
                    
                case .view(.stopWorkout):
                    return .none
                }
            }
        }
    }
}

import ComposableArchitecture
import Foundation

/// Implementation of `HeartRateFeature` state
extension HeartRateFeature {
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        case heartRateUpdated(Double)
        
        case view(View)
        
        /// Sub-actions for view-related events.
        enum View {
            case startWorkout
            case stopWorkout
        }
    }
}

import ComposableArchitecture
import Foundation

/// Implementation of `HeartRateFeature` state
extension HeartRateFeature {
    @ObservableState
    struct State: Equatable {
        var heartRate: Int = 0
    }
}


