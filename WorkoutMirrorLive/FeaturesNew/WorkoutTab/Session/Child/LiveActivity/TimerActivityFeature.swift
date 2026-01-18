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

/// A feature responsible for managing the Timer Live Activity.
/// It handles starting, updating, and stopping the Live Activity, as well as managing the timer state.
@Reducer
struct TimerActivityFeature {
    
    // MARK: - Dependencies

    /// Client for interacting with the Live Activity API.
    @Dependency(\.liveActivityClient) var liveActivityClient
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        /// The unique identifier of the active Live Activity, if any.
        var activityID: String?
        
        /// The current operational state of the timer (running, paused, stopped).
        var timerState: TimerState = .stopped
        
        /// The elapsed time of the timer in seconds.
        var elapsedTime: TimeInterval = 0
        
        /// Indicates whether a Live Activity is currently active.
        var isActive: Bool {
            activityID != nil
        }
        
        /// Enumeration representing possible states of the timer.
        enum TimerState: Equatable {
            /// Timer is currently running.
            case running
            /// Timer has been paused.
            case paused
            /// Timer is stopped.
            case stopped
        }
    }
    
    // MARK: - Actions
    
    enum Action: Equatable {
        // MARK: Live Activity Lifecycle
        
        /// Request to start the timer Live Activity with a name and initial content state.
        case start(timerName: String, initialState: TimerActivityAttributes.ContentState)
        
        /// Request to update the existing Live Activity with new content state.
        case update(TimerActivityAttributes.ContentState)
        
        /// Request to stop and dismiss the current Live Activity.
        case stop
        
        // MARK: Timer Controls
        
        /// Pause the timer (logic and UI update).
        case pauseTimer
        
        /// Resume the timer (logic and UI update).
        case resumeTimer
        
        /// Reset the timer to zero.
        case resetTimer
        
        // MARK: Internal Actions
        
        /// Internal action triggered when the Live Activity successfully starts.
        case activityStarted(activityID: String)
        
        /// Internal action triggered when the Live Activity successfully stops.
        case activityStopped
    }
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
            // MARK: - Lifecycle Handlers
                
            case let .start(timerName, initialState):
                guard !state.isActive else {
                    print("⚠️ [TimerActivityFeature] Already active")
                    return .none
                }
                
                print("⏱️ [TimerActivityFeature] Starting: \(timerName)")
                
                return .run { send in
                    do {
                        let activityID = try await liveActivityClient.startTimer(timerName, initialState)
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
                        try await liveActivityClient.updateTimer(activityID, newState)
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
                        try await liveActivityClient.stopTimer(activityID)
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
