//
//  SummaryFeature.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 19/05/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct SummaryFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.dismiss) var dismiss
    
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
                case .view(.doneButtonPressed):
                    print("SummaryFeature - doneButtonPressed")
                    return .run { send in
                        await self.dismiss()
                    }
                }
            }
        }
    }
}


import ComposableArchitecture
import Foundation

/// Implementation of `SummaryFeature` state
extension SummaryFeature {
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
            case doneButtonPressed
        }
    }
    
}

import ComposableArchitecture
import Foundation

/// Implementation of `SummaryFeature` state
extension SummaryFeature {
    @ObservableState
    struct State: Equatable {}
}
