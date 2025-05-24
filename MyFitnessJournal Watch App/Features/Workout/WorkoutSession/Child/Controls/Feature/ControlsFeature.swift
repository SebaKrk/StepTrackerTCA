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
    
    // MARK: - Properties
    
    var service: ControlsService
    
    // MARK: - Lifecycle
    
    init(service: ControlsService = DefaultControlsService()) {
        self.service = service
    }
    
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
                case .view(.endButtonPressed):
                    service.endWorkout()
                    return .none
                    
                case .view(.togglePauseButtonPressed):
                    service.togglePause()
                    state.workoutSessionIsRunning = service.workoutSessionIsRunning
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
        
        // MARK: - Actions View
        
        case view(View)
        
        /// Sub-actions for view-related events.
        enum View {
            
            ///
            case endButtonPressed
            
            ///
            case togglePauseButtonPressed
            
            
        }
    }
    
}

import ComposableArchitecture
import Foundation

/// Implementation of `ControlsFeature` state
extension ControlsFeature {
    @ObservableState
    struct State: Equatable {
        
        var workoutSessionIsRunning: Bool = false
        
    }
}
