//
//  WorkoutGeneratorFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 27/06/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
struct WorkoutGeneratorFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        CombineReducers {
            BindingReducer()
            Reduce { state, action in
                switch action {
                    
                    // MARK: - Binding
                    
                case .binding(_):
                    return .none
                    
                    // MARK: - View Actions
                    
                case .view(.viewDidAppear):
                    return .none
                }
            }
        }
    }
    
}

// MARK: - Action

/// Implementation of `WorkoutGeneratorFeature` action
extension WorkoutGeneratorFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - View actions
        
        /// Used for view actions.
        case view(View)
        
        enum View {
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
            
        }
    }
}

// MARK: - State

/// Implementation of `WorkoutGeneratorFeature` state
extension WorkoutGeneratorFeature {
    
    @ObservableState
    struct State {
        
        ///
        var recognizedText: String
        
    }
}

