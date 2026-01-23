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
                    print("⚠️ [WorkoutActivityFeature] Already active")
                    return .none
                }
                
                print("🚀 [WorkoutActivityFeature] Starting: \(workoutName)")
                
                return .run { send in
                    do {
                        let activityID = try await workoutActivityClient.start(workoutName, initialState)
                        await send(.activityStarted(activityID: activityID))
                    } catch {
                        print("❌ [WorkoutActivityFeature] Start failed: \(error)")
                    }
                }
                
            case let .activityStarted(activityID):
                state.activityID = activityID
                print("✅ [WorkoutActivityFeature] Started: \(activityID)")
                return .none
                
            case let .update(newState):
                guard let activityID = state.activityID else {
                    return .none
                }
                
                return .run { _ in
                    do {
                        try await workoutActivityClient.update(activityID, newState)
                    } catch {
                        print("❌ [WorkoutActivityFeature] Update failed: \(error)")
                    }
                }
                
            case .stop:
                guard let activityID = state.activityID else {
                    return .none
                }
                
                print("🛑 [WorkoutActivityFeature] Stopping: \(activityID)")
                
                return .run { send in
                    do {
                        try await workoutActivityClient.stop(activityID)
                        await send(.activityStopped)
                    } catch {
                        print("❌ [WorkoutActivityFeature] Stop failed: \(error)")
                    }
                }
                
            case .activityStopped:
                state.activityID = nil
                print("✅ [WorkoutActivityFeature] Stopped")
                return .none
            }
        }
    }
}
