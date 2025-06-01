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
    @Dependency(\.trainingSessionClient) var client
    
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
                case .changeSummaryState:
                    client.setShowingSummary(false)
                    return .none
                    
                    // MARK: - View Actions
                case .view(.doneButtonPressed):
                    print("SummaryFeature - doneButtonPressed")
                    
                    return .run { send in
                        await send(.changeSummaryState)
                        await self.dismiss()
                    }
                }
            }
        }
    }
}


import ComposableArchitecture
import Foundation

/// Implementation of `TrainingSummaryFeature` state
extension TrainingSummaryFeature {
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        /// Updates the summary state, typically used to hide or reset the summary screen.
        case changeSummaryState
        
        // MARK: - Actions View
        
        case view(View)
        
        /// Sub-actions for view-related events.
        enum View {
            
            /// Called when the user taps the Done button to close the summary view.
            case doneButtonPressed
        }
    }
    
}

import ComposableArchitecture
import Foundation

/// Implementation of `TrainingSummaryFeature` state
extension TrainingSummaryFeature {
    @ObservableState
    struct State: Equatable {}
}

