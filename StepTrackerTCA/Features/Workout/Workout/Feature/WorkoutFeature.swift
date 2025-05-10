//
//  WorkoutFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 10/05/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct WorkoutFeature {
    
    // MARK: - Properties
    
    // MARK: - Lifecycle
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                // MARK: - Actions
                
                // MARK: - View Actions
                
            case .view(.viewDidAppear):
                
                return .none
            }
        }
    }
    
}


/// Implementation of `WorkoutFeature` action
extension WorkoutFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        // MARK: - View actions
        
        /// Used for view actions.
        case view(View)
        
        enum View {
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
        }
    }
}

/// Implementation of `WorkoutFeature` state
extension WorkoutFeature {
    @ObservableState
    struct State {
        
    }
}
    
    
