//
//  MovementHistoryFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 14/04/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct MovementHistoryFeature {
    
    // MARK: - Dependencies
    
    // MARK: - Livecycle
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
            case .view(.viewDidAppear):
                print("MovementHistoryFeature")
                return .none
            }
        }
    }
}

import ComposableArchitecture
import Foundation

/// Implementation of `MovementHistoryFeature` action
extension MovementHistoryFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        // MARK: - View Actions
        
        /// View-specific actions triggered by UI events.
        case view(View)
        
        enum View {
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
        }
    }
    
}

import ComposableArchitecture
import Foundation

/// Implementation of `MovementHistoryFeature` state
extension MovementHistoryFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        var selectedMovement: GroupedMovement
        
    }
}
