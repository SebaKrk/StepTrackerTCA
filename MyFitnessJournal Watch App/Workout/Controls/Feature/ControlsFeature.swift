//
//  ControlsFeature.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 19/05/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ControlsFeature {
    
    // MARK: - Dependencies
    
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
                case .view(.endButtonPressed):
                    return .none
                    
                case .view(.playPauseButtonPressed):
                    return .none
                
                }
            }
        }
    }
    
}

import ComposableArchitecture
import Foundation

/// Implementation of `ControlsFeature` state
extension ControlsFeature {
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        case view(View)
        
        /// Sub-actions for view-related events.
        enum View {
            
            ///
            case endButtonPressed
            
            ///
            case playPauseButtonPressed
            
        }
    }
    
}

import ComposableArchitecture
import Foundation

/// Implementation of `ControlsFeature` state
extension ControlsFeature {
    @ObservableState
    struct State: Equatable {
        
    }
}
