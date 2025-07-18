//
//  WorkoutPreviewFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 17/07/2025.
//

import Foundation
import ComposableArchitecture

@Reducer
struct WorkoutPreviewFeature {
    
    // MARK: - Reducer
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
                
                // MARK: - Binding
            case .binding(_):
                return .none
                
                // MARK: - Actions

                // MARK: - View Actions
            }
        }
    }
    
}
// MARK: - Action

/// Implementation of `WorkoutPreviewFeature` action
extension WorkoutPreviewFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        case binding(BindingAction<State>)
        
        // MARK: - Actions

        // MARK: - View actions
        case view(View)
        
        enum View { }
    }
}

// MARK: - State

/// Implementation of `WorkoutPreview` state
extension WorkoutPreviewFeature {
    
    @ObservableState
    struct State {
        
        // MARK: Properties
        
        let trainingSession: TrainingSession
        
    }
    
}
