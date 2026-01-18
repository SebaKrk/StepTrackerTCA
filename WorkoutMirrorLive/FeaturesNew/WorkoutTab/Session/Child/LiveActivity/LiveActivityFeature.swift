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
        var workout = WorkoutActivityFeature.State()
        var timer = TimerActivityFeature.State()
        
        /// Convenience: any LA active?
        var hasActiveActivity: Bool {
            workout.isActive || timer.isActive
        }
        
        /// Convenience: which LA is active?
        var activeType: LiveActivityType? {
            if workout.isActive { return .workout }
            if timer.isActive { return .timer }
            return nil
        }
    }
    
    // MARK: - Actions
    
    enum Action: Equatable {
        case workout(WorkoutActivityFeature.Action)
        case timer(TimerActivityFeature.Action)
    }
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
            // MARK: - Coordination Logic
                
            case .workout(.start):
                // Stop timer if active before starting workout
                // Scope will automatically forward this action to WorkoutActivityFeature
                if state.timer.isActive {
                    print("🔄 [LiveActivityFeature] Stopping timer to start workout")
                    return .send(.timer(.stop))
                }
                return .none
                
            case .timer(.start):
                // Stop workout if active before starting timer
                // Scope will automatically forward this action to TimerActivityFeature
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
