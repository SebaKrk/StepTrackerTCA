//  TimerActivityFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 17/01/2026.
//

import ActivityKit
import ComposableArchitecture
import Foundation
import HealthHub
import SharedModels

/// A feature responsible for managing the Live Activity.
@Reducer
struct TimerActivityFeature {
    
    // MARK: - Dependencies

    /// Client for interacting with the Timer Live Activity.
    @Dependency(\.timerActivityClient) var timerActivityClient
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        /// The unique identifier of the active Live Activity.
        var activityID: String?
        
        /// The current local state of the timer (running, paused, stopped).
        var timerState: TimerState = .stopped
        
        /// The elapsed time of the timer in seconds.
        var elapsedTime: TimeInterval = 0
        
        /// Indicates if a Live Activity is currently active.
        var isActive: Bool {
            activityID != nil
        }
        
        /// Represents the operational state of the timer.
        enum TimerState: Equatable {
            /// The timer is currently counting up.
            case running
            /// The timer is halted but active.
            case paused
            /// The timer is fully stopped and inactive.
            case stopped
        }
    }
    
    // MARK: - Actions
    
    enum Action: Equatable {
        /// Starts the Timer Live Activity with the given name and initial state.
        case start(timerName: String, initialState: TimerActivityAttributes.ContentState)
        
        /// Updates the existing Live Activity with new content state.
        case update(TimerActivityAttributes.ContentState)
        
        /// Stops and ends the current Live Activity.
        case stop
        
        /// Pauses the local timer state.
        case pauseTimer
        
        /// Resumes the local timer state.
        case resumeTimer
        
        /// Resets the local timer elapsed time.
        case resetTimer
        
        /// Internal action sent when the Live Activity successfully starts.
        case activityStarted(activityID: String)
        
        /// Internal action sent when the Live Activity ends or is dismissed.
        case activityStopped
        
        /// Internal action triggered when the Activity is updated externally (e.g., from an App Intent).
        case activityUpdated(TimerActivityAttributes.ContentState)
    }
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
            case let .start(timerName, initialState):
                guard !state.isActive else { return .none }
                return .run { send in
                    do {
                        let activityID = try await timerActivityClient.start(timerName, initialState)
                        await send(.activityStarted(activityID: activityID))
                    } catch {
                        print("❌ [TimerActivityFeature] Start failed: \(error)")
                    }
                }
                
            case let .activityStarted(activityID):
                state.activityID = activityID
                state.timerState = .running
                print("✅ [TimerActivityFeature] Started: \(activityID)")
                
                return .run { send in
                    let activities = Activity<TimerActivityAttributes>.activities
                    guard let activity = activities.first(where: { $0.id == activityID }) else { return }
                    
                    print("👁️ [TimerActivityFeature] Observing updates for \(activityID)")
                    
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask {
                            for await contentUpdate in activity.contentUpdates {
                                await send(.activityUpdated(contentUpdate.state))
                            }
                        }
                        
                        group.addTask {
                            for await stateUpdate in activity.activityStateUpdates {
                                if stateUpdate == .dismissed || stateUpdate == .ended {
                                    print("🛑 [TimerActivityFeature] Activity ended/dismissed externally")
                                    await send(.activityStopped)
                                }
                            }
                        }
                    }
                }
                
            case let .activityUpdated(newState):
                state.timerState = newState.isRunning ? .running : .paused
                print("🔄 [TimerActivityFeature] Synced state: isRunning=\(newState.isRunning)")
                return .none
                
            case let .update(newState):
                guard let activityID = state.activityID else { return .none }
                return .run { _ in
                    do {
                        try await timerActivityClient.update(activityID, newState)
                    } catch {
                        print("⚠️ [TimerActivityFeature] Update failed: \(error)")
                    }
                }
                
            case .stop:
                guard let activityID = state.activityID else { return .none }
                return .run { send in
                    do {
                        try await timerActivityClient.stop(activityID)
                    } catch {
                        print("⚠️ [TimerActivityFeature] Stop failed: \(error)")
                    }
                    await send(.activityStopped)
                }
                
            case .activityStopped:
                state.activityID = nil
                state.timerState = .stopped
                state.elapsedTime = 0
                return .none
                
            case .pauseTimer:
                state.timerState = .paused
                return .none
                
            case .resumeTimer:
                state.timerState = .running
                return .none
                
            case .resetTimer:
                state.elapsedTime = 0
                return .none
            }
        }
    }
}
