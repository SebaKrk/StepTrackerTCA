//
//  WorkoutSummaryFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 13/08/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
struct WorkoutSummaryFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        CombineReducers {
            BindingReducer()
            Reduce { state, action in
                switch action {
                    
                    // MARK: - Binding
                case .binding(_):
                    return .none
                    
                    // MARK: - Action
                case let .changeViewState(viewState):
                    state.viewState = viewState
                    return .none
                    
                    // MARK: - View Action
                case .view(.viewDidAppear):
                    return .none
                }
            }
        }
    }
    
}

/// Implementation of `WorkoutSummaryFeature` action
extension WorkoutSummaryFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        /// Responsible for changing the state of the view.
        case changeViewState(WorkoutSummaryState)
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
        }
    }
}

/// Implementation of `WorkoutSummaryFeature` state
extension WorkoutSummaryFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        ///
        var viewState: WorkoutSummaryState = .loading
        
        ///
        var summary: WorkoutSummary? = nil
    }
    
}
