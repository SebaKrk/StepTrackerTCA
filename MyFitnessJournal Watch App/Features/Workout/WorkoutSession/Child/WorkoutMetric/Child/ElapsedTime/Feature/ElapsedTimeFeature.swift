//
//  ElapsedTimeFeature.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 22/05/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ElapsedTimeFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        CombineReducers {
            BindingReducer()
            Reduce { state, action in
                switch action {
                    
                    // MARK: - Binding
                case .binding(_):
                    return .none
                }
            }
        }
    }
    
}

import ComposableArchitecture
import Foundation

/// Implementation of `ElapsedTimeFeature` state
extension ElapsedTimeFeature {
    
    @CasePathable
    enum Action: BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
    }
    
}

import ComposableArchitecture
import Foundation

/// Implementation of `ElapsedTimeFeature` state
extension ElapsedTimeFeature {
    @ObservableState
    struct State: Equatable {
        
        var elapsedTime: TimeInterval = 0
        
        var showSubseconds: Bool = true
        
    }
}
