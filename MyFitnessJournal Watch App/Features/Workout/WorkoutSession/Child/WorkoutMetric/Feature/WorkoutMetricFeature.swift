//
//  WorkoutMetricFeature.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 22/05/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct WorkoutMetricFeature {
    
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
                    
                    // MARK: - View Actions
                case .view(.startHeartAnimation):
                    state.animateHeart = true
                    return .none
                }
            }
        }
    }
    
}

import ComposableArchitecture
import Foundation

/// Implementation of `WorkoutMetricFeature` state
extension WorkoutMetricFeature {
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        case view(View)
        
        /// Sub-actions for view-related events.
        enum View {
            
            case startHeartAnimation
        }
    }
    
}

import ComposableArchitecture
import Foundation

/// Implementation of `WorkoutMetricFeature` state
extension WorkoutMetricFeature {
    @ObservableState
    struct State: Equatable {

        var animateHeart: Bool = false
    }
}
