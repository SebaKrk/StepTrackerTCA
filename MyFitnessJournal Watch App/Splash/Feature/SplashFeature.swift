//
//  SplashFeature.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 18/05/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct SplashFeature {
    
    // MARK: - Dependencies
    
    @Dependency(\.continuousClock) var clock
    
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
                case .view(.viewDidAppear):
                    return .run { send in
                        try await clock.sleep(for: .seconds(3))
                        await send(.view(.showMainApp), animation: .easeInOut)
                    }
                    
                case .view(.showMainApp):
                    state.isActive = true
                    return .none
                    
                }
            }
        }
    }
}

import ComposableArchitecture
import Foundation

/// Implementation of `SplashFeature` state
extension SplashFeature {
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        case view(View)
        
        /// Sub-actions for view-related events.
        enum View {
            
            /// Triggered when the view appears.
            case viewDidAppear
            
            ///
            case showMainApp
        }
    }
    
}

import ComposableArchitecture
import Foundation

/// Implementation of `SplashFeature` state
extension SplashFeature {
    @ObservableState
    struct State: Equatable {
        
        var isActive: Bool = false
    }
}

