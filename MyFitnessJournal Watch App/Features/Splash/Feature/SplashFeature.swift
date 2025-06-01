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
                    
                    // MARK: - View Actions
                case .view(.viewDidAppear):
                    return .run { send in
                        try await clock.sleep(for: .seconds(3))
                        await send(.view(.showMainApp), animation: .bouncy)
                    }
                    
                case .view(.showMainApp):
                    state.isActive = true
                    return .none
                    
                }
            }
        }
    }
}
