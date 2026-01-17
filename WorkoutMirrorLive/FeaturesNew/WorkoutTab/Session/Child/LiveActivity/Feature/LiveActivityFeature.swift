//
//  LiveActivityFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 17/01/2026.
//

import ComposableArchitecture
import Foundation
import HealthHub
import SharedModels

/// A dedicated reducer for managing Live Activities (Workout, Timer, etc.)
/// Separates Live Activity logic from the main LiveSessionFeature for better modularity.
@Reducer
struct LiveActivityFeature {
    
    // MARK: - Dependencies
    
    @Dependency(\.liveActivityClient) var liveActivityClient

    // MARK: - Reducer Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
            // MARK: - Workout Live Activity
                
            case let .startWorkout(workoutName, initialState):
                // Don't start if already active
                guard !state.isWorkoutActive else {
                    print("⚠️ [LiveActivityFeature] Workout activity already active")
                    return .none
                }
                
                print("🚀 [LiveActivityFeature] Starting workout activity: \(workoutName)")
                
                return .run { send in
                    do {
                        let activityID = try await liveActivityClient.start(
                            workoutName,
                            initialState
                        )
                        await send(.workoutActivityStarted(activityID: activityID))
                    } catch {
                        print("❌ [LiveActivityFeature] Failed to start workout activity: \(error)")
                    }
                }
                
            case let .workoutActivityStarted(activityID):
                state.activeActivities[.workout] = activityID
                print("✅ [LiveActivityFeature] Workout activity started: \(activityID)")
                return .none
                
            case let .updateWorkout(newState):
                guard let activityID = state.activeActivities[.workout] else {
                    print("⚠️ [LiveActivityFeature] No active workout to update")
                    return .none
                }
                
                return .run { send in
                    do {
                        try await liveActivityClient.update(activityID, newState)
                    } catch {
                        print("❌ [LiveActivityFeature] Failed to update workout activity: \(error)")
                    }
                }
                
            case .stopWorkout:
                guard let activityID = state.activeActivities[.workout] else {
                    print("⚠️ [LiveActivityFeature] No active workout to stop")
                    return .none
                }
                
                print("🛑 [LiveActivityFeature] Stopping workout activity: \(activityID)")
                
                return .run { send in
                    do {
                        try await liveActivityClient.stop(activityID)
                        await send(.workoutActivityStopped)
                    } catch {
                        print("❌ [LiveActivityFeature] Failed to stop workout activity: \(error)")
                    }
                }
                
            case .workoutActivityStopped:
                state.activeActivities[.workout] = nil
                print("✅ [LiveActivityFeature] Workout activity stopped")
                return .none
            }
        }
    }
}
