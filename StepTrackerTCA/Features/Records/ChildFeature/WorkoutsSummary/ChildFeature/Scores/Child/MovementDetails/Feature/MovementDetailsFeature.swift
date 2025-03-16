//
//  MovementDetailsFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/03/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct MovementDetailsFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
            case .view(.viewDidAppear):
                dump(state.sessions)
                return .none
            }
        }
    }
    
}

import ComposableArchitecture
import Foundation

/// Implementation of `MovementDetailsFeature` action
extension MovementDetailsFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
        }
    }
}


import ComposableArchitecture
import Foundation

/// Implementation of `MovementDetailsFeature` state
extension MovementDetailsFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        let movement: any MovementType
        
        let sessions: [any WorkoutSession]
    }
}
