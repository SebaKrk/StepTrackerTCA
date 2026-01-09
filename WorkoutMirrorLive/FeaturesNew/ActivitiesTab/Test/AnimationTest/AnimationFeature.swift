//
//  AnimationFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 21/09/2025.
//


import ComposableArchitecture
import Foundation

@Reducer
struct AnimationFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Action
                
                // MARK: - View Action
            case .view(.viewDidAppear):
                return .none
                
            case .view(.incrementButtonTapped):
                state.counter += 1
                return .none
            }
        }
    }
}

/// Implementation of `AnimationFeature` action
extension AnimationFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
            
            case incrementButtonTapped
        }
    }
}

/// Implementation of `AnimationFeature` state
extension AnimationFeature {
    
    @ObservableState
    struct State {
        
        var counter: Float = 0
    }
    
}

