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
    
    // MARK: - State
    @ObservableState
    struct State {
        var selectedMovement: GroupedMovement
    }
    
    // MARK: - Action
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - View Actions
        
        /// View-specific actions triggered by UI events.
        case view(View)
        
        enum View {
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
        }
    }
    
    // MARK: - Reducer
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
            case .view(.viewDidAppear):
                return .none
            }
        }
    }
    
}
