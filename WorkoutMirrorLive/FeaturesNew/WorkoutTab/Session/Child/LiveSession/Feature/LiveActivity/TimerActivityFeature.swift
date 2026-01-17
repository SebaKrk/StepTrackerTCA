//
//  TimerActivityFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 17/01/2026.
//

import ComposableArchitecture
import Foundation
import HealthHub
import SharedModels

/// Manages Timer-specific Live Activity (HR + timer controls)
@Reducer
struct TimerActivityFeature {
    
    @Dependency(\.liveActivityClient) var liveActivityClient
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        /// ID of active timer Live Activity
        var activityID: String?
        
        /// Timer state
        var timerState: TimerState = .stopped
        var elapsedTime: TimeInterval = 0
        
        var isActive: Bool {
            activityID != nil
        }
        
        enum TimerState: Equatable {
            case running
            case paused
            case stopped
        }
    }
    
    // MARK: - Actions
    
    enum Action: Equatable {
        /// Start timer Live Activity with workout metrics
        case start(workoutName: String, initialState: WorkoutSessionActivityAttributes.ContentState)
        
        /// Update workout metrics (HR, energy, etc.)
        case update(WorkoutSessionActivityAttributes.ContentState)
        
        /// Stop and dismiss timer Live Activity
        case stop
        
        // Timer controls
        case pauseTimer
        case resumeTimer
        case resetTimer
        
        // Internal
        case activityStarted(activityID: String)
        case activityStopped
    }
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
            case let .start(workoutName, initialState):
                guard !state.isActive else {
                    print("⚠️ [TimerActivityFeature] Already active")
                    return .none
                }
                
                print("⏱️ [TimerActivityFeature] Starting: \(workoutName)")
                
                return .run { send in
                    do {
                        let activityID = try await liveActivityClient.start(workoutName, initialState)
                        await send(.activityStarted(activityID: activityID))
                    } catch {
                        print("❌ [TimerActivityFeature] Start failed: \(error)")
                    }
                }
                
            case let .activityStarted(activityID):
                state.activityID = activityID
                state.timerState = .running
                print("✅ [TimerActivityFeature] Started: \(activityID)")
                return .none
                
            case let .update(newState):
                guard let activityID = state.activityID else {
                    return .none
                }
                
                return .run { _ in
                    do {
                        try await liveActivityClient.update(activityID, newState)
                    } catch {
                        print("❌ [TimerActivityFeature] Update failed: \(error)")
                    }
                }
                
            case .stop:
                guard let activityID = state.activityID else {
                    return .none
                }
                
                print("🛑 [TimerActivityFeature] Stopping: \(activityID)")
                
                return .run { send in
                    do {
                        try await liveActivityClient.stop(activityID)
                        await send(.activityStopped)
                    } catch {
                        print("❌ [TimerActivityFeature] Stop failed: \(error)")
                    }
                }
                
            case .activityStopped:
                state.activityID = nil
                state.timerState = .stopped
                state.elapsedTime = 0
                print("✅ [TimerActivityFeature] Stopped")
                return .none
                
            // MARK: - Timer Controls
                
            case .pauseTimer:
                state.timerState = .paused
                print("⏸️ [TimerActivityFeature] Timer paused")
                // TODO: Update LA to show paused state
                return .none
                
            case .resumeTimer:
                state.timerState = .running
                print("▶️ [TimerActivityFeature] Timer resumed")
                // TODO: Update LA to show running state
                return .none
                
            case .resetTimer:
                state.elapsedTime = 0
                print("🔄 [TimerActivityFeature] Timer reset")
                // TODO: Update LA to show reset time
                return .none
            }
        }
    }
}
