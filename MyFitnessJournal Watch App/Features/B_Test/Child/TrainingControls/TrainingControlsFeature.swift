//
//  TrainingControlsFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 28/05/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct TrainingControlsFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                // MARK: - View Actions
            case .view(.endButtonPressed):
                return .none
                
            case .view(.togglePauseButtonPressed):
                return .none
            }
        }
    }
}


/// Implementation of `TrainingControlsFeature` state
extension TrainingControlsFeature {
    @CasePathable
    enum Action: ViewAction{
        
        // MARK: - Actions View
        
        case view(View)
        
        /// Sub-actions for view-related events.
        enum View {
            
            ///
            case endButtonPressed
            
            ///
            case togglePauseButtonPressed
        }
    }
    
}

/// Implementation of `TrainingControlsFeature` state
extension TrainingControlsFeature {
    
    @ObservableState
    struct State: Equatable {
        var sessionIsRunning: Bool
    }
    
}
