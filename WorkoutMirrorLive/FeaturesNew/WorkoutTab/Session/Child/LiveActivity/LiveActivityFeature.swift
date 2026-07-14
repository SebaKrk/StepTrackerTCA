//
//  LiveActivityFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 17/01/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

/// Coordinator for all Live Activity types
/// Manages multiple LA children and ensures mutual exclusion
@Reducer
struct LiveActivityFeature {
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        /// State for the Workout Live Activity.
        var workout = WorkoutActivityFeature.State()
        
        /// State for the Timer Live Activity.
        var timer = TimerActivityFeature.State()
        
        /// Indicates if any Live Activity (Workout or Timer) is currently active.
        var hasActiveActivity: Bool {
            workout.isActive || timer.isActive
        }
        
        /// Returns the type of the currently active Live Activity, or nil if none.
        var activeType: LiveActivityType? {
            if workout.isActive { return .workout }
            if timer.isActive { return .timer }
            return nil
        }
    }
    
    // MARK: - Actions
    
    enum Action: Equatable {
        /// Actions delegated to the Workout Live Activity feature.
        case workout(WorkoutActivityFeature.Action)
        
        /// Actions delegated to the Timer Live Activity feature.
        case timer(TimerActivityFeature.Action)
    }
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
            // MARK: - Coordination Logic
                
            case .workout(.start):
                // Ensure mutual exclusion: Stop timer if active
                if state.timer.isActive {
                    print("🔄 [LiveActivityFeature] Stopping timer to start workout")
                    return .send(.timer(.stop))
                }
                return .none
                
            case .timer(.start):
                // Ensure mutual exclusion: Stop workout if active
                if state.workout.isActive {
                    print("🔄 [LiveActivityFeature] Stopping workout to start timer")
                    return .send(.workout(.stop))
                }
                return .none
                
            // All other actions forwarded to children via Scope
            case .workout, .timer:
                return .none
            }
        }
        
        Scope(state: \.workout, action: \.workout) {
            WorkoutActivityFeature()
        }
        
        Scope(state: \.timer, action: \.timer) {
            TimerActivityFeature()
        }
    }
}
