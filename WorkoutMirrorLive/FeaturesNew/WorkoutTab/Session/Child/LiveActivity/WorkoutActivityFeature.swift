//
//  WorkoutActivityFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 17/01/2026.
//

import ComposableArchitecture
import Foundation
import HealthHub
import SharedModels

/// Manages Workout-specific Live Activity (HR, zones, energy)
@Reducer
struct WorkoutActivityFeature {
    
    @Dependency(\.workoutActivityClient) var workoutActivityClient
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        /// ID of active workout Live Activity
        var activityID: String?
        
        var isActive: Bool {
            activityID != nil
        }
    }
    
    // MARK: - Actions
    
    enum Action: Equatable {
        /// Start workout Live Activity
        case start(workoutName: String, initialState: WorkoutSessionActivityAttributes.ContentState)
        
        /// Update workout metrics
        case update(WorkoutSessionActivityAttributes.ContentState)
        
        /// Stop workout Live Activity
        case stop
        
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
                    #if DEBUG
                    print("⚠️ [WorkoutActivityFeature] Already active")
                    #endif
                    return .none
                }
                
                #if DEBUG
                print("🚀 [WorkoutActivityFeature] Starting: \(workoutName)")
                #endif
                
                return .run { send in
                    do {
                        let activityID = try await workoutActivityClient.start(workoutName, initialState)
                        await send(.activityStarted(activityID: activityID))
                    } catch {
                        #if DEBUG
                        print("❌ [WorkoutActivityFeature] Start failed: \(error)")
                        #endif
                    }
                }
                
            case let .activityStarted(activityID):
                state.activityID = activityID
                #if DEBUG
                print("✅ [WorkoutActivityFeature] Started: \(activityID)")
                #endif
                return .none
                
            case let .update(newState):
                guard let activityID = state.activityID else {
                    return .none
                }
                
                return .run { _ in
                    do {
                        try await workoutActivityClient.update(activityID, newState)
                    } catch {
                        #if DEBUG
                        print("❌ [WorkoutActivityFeature] Update failed: \(error)")
                        #endif
                    }
                }
                
            case .stop:
                guard let activityID = state.activityID else {
                    return .none
                }

                // Cleared before the call, not after it: `Activity.end` is an IPC
                // round trip that ignores task cancellation, so a `send` placed
                // after it lands on a presentation the session already dismissed.
                state.activityID = nil

                return .run { _ in
                    do {
                        try await workoutActivityClient.stop(activityID)
                    } catch {
                        #if DEBUG
                        print("❌ [WorkoutActivityFeature] Stop failed: \(error)")
                        #endif
                    }
                }
                
            case .activityStopped:
                state.activityID = nil
                #if DEBUG
                print("✅ [WorkoutActivityFeature] Stopped")
                #endif
                return .none
            }
        }
    }
}
