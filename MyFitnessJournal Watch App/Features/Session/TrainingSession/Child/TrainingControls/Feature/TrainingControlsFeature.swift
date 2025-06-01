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
        
        /// Handles user-triggered events from the training controls view.
        case view(View)
        
        /// Sub-actions for view-related events.
        enum View {
            
            /// Called when the user taps the End button to stop the workout session.
            case endButtonPressed
            
            /// Called when the user taps the Pause/Resume button to toggle session state.
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
