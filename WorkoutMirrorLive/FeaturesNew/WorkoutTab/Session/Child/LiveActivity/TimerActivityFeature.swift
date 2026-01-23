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
        var activityID: String?
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
        case start(timerName: String, initialState: TimerActivityAttributes.ContentState)
        case update(TimerActivityAttributes.ContentState)
        case stop
        
        case pauseTimer
        case resumeTimer
        case resetTimer
        
        case activityStarted(activityID: String)
        case activityStopped
        /// Internal action triggered when Activity is updated externally (e.g. from Intent)
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
                
                // Start observing Activity updates from Intents
                return .run { send in
                    let activities = Activity<TimerActivityAttributes>.activities
                    guard let activity = activities.first(where: { $0.id == activityID }) else { return }
                    
                    print("👁️ [TimerActivityFeature] Observing updates for \(activityID)")
                    
                    await withTaskGroup(of: Void.self) { group in
                        // Observe Content Updates (Play/Pause)
                        group.addTask {
                            for await contentUpdate in activity.contentUpdates {
                                await send(.activityUpdated(contentUpdate.state))
                            }
                        }
                        
                        // Observe State Updates (Stop/Dismiss)
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
                    try await timerActivityClient.update(activityID, newState)
                }
                
            case .stop:
                guard let activityID = state.activityID else { return .none }
                return .run { send in
                    try await timerActivityClient.stop(activityID)
                    await send(.activityStopped)
                }
                
            case .activityStopped:
                state.activityID = nil
                state.timerState = .stopped
                state.elapsedTime = 0
                return .none
                
            case .pauseTimer:
                state.timerState = .paused
                // Logic to update Live Activity via Client if needed from App UI
                return .none
                
            case .resumeTimer:
                state.timerState = .running
                // Logic to update via Client
                return .none
                
            case .resetTimer:
                state.elapsedTime = 0
                return .none
            }
        }
    }
}
