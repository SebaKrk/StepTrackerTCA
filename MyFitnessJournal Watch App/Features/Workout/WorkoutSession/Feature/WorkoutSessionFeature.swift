//
//  WorkoutSessionFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 19/05/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct WorkoutSessionFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        
        Reduce { state, action in
            switch action {
                
            case let .tabChanged(tabItem):
                state.selectedTab = tabItem
                
                return .none
            case .controlsFeature(_):
                return .none
                
            case .workoutMetricFeature(_):
                return .none
            }
            
        }
        
        Scope(state: \.controlsFeature, action: \.controlsFeature) {
            ControlsFeature()
        }
        Scope(state: \.workoutMetricFeature, action: \.workoutMetricFeature) {
            WorkoutMetricFeature()
        }
    }
}

/// Implementation of `WorkoutSessionFeature` action
extension WorkoutSessionFeature {
    
    @CasePathable
    enum Action {
        
        /// Action triggered when the user changes the selected tab.
        case tabChanged(WorkoutSessionScreenAW)
        
        // MARK: - Child Actions
        
        ///
        case controlsFeature(ControlsFeature.Action)
        
        ///
        case workoutMetricFeature(WorkoutMetricFeature.Action)
    }
    
}

/// Implementation of `WorkoutSessionFeature` state
extension WorkoutSessionFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// The currently selected tab in the application.
        ///
        /// Default value is `.workout`.
        var selectedTab: WorkoutSessionScreenAW = .workout
        
        // MARK: - Child State
        
        ///
        var controlsFeature = ControlsFeature.State()
        
        ///
        var workoutMetricFeature = WorkoutMetricFeature.State()
    }
    
}
