//
//  TrainingReadinessFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 26/09/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct TrainingReadinessFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
                
                // MARK: - Action
                
                // MARK: - View Actions
                
            case .view(.viewDidAppear):
                return .none
                
            }
        }
    }
}


/// Implementation of `TrainingReadinessFeature` action
extension TrainingReadinessFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Action
        
        // MARK: - View actions
        
        /// Used for view actions.
        case view(View)
        
        enum View {
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
        }
    }
}

/// Implementation of `TrainingReadinessFeature` state
extension TrainingReadinessFeature {
    
    @ObservableState
    struct State {
    }
}
