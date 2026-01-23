//
//  WorkoutActivityClient.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 23/01/2026.
//

import ActivityKit
import ComposableArchitecture
import Foundation
import SharedModels

@DependencyClient
public struct WorkoutActivityClient: Sendable {
    
    /// Starts a new Live Activity for workout session
    /// - Parameters:
    ///   - workoutName: Name of the workout
    ///   - initialState: Initial content state with workout metrics
    /// - Returns: Activity ID that can be used to update or stop the activity
    public var start: @Sendable (
        _ workoutName: String,
        _ initialState: WorkoutSessionActivityAttributes.ContentState
    ) async throws -> String = { _, _ in "" }
    
    /// Updates the Live Activity with new workout metrics
    /// - Parameters:
    ///   - activityId: ID of the activity to update
    ///   - newState: New content state with updated metrics
    public var update: @Sendable (
        _ activityId: String,
        _ newState: WorkoutSessionActivityAttributes.ContentState
    ) async throws -> Void
    
    /// Stops and dismisses the Live Activity
    /// - Parameter activityId: ID of the activity to stop
    public var stop: @Sendable (
        _ activityId: String
    ) async throws -> Void
}

// MARK: - DependencyKey

extension WorkoutActivityClient: DependencyKey {
    public static let liveValue = Self(
        start: { workoutName, initialState in
            let attributes = WorkoutSessionActivityAttributes(
                workoutName: workoutName,
                startTime: Date()
            )
            
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            
            return activity.id
        },
        update: { activityId, newState in
            let activities = Activity<WorkoutSessionActivityAttributes>.activities
            guard let activity = activities.first(where: { $0.id == activityId }) else {
                throw LiveActivityError.activityNotFound
            }
            
            await activity.update(
                .init(state: newState, staleDate: nil)
            )
        },
        stop: { activityId in
            let activities = Activity<WorkoutSessionActivityAttributes>.activities
            guard let activity = activities.first(where: { $0.id == activityId }) else {
                throw LiveActivityError.activityNotFound
            }
            
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    )
    
    public static let previewValue = Self(
        start: { workoutName, initialState in
            print("🟢 [Workout Preview] Started: \(workoutName)")
            print("   Initial HR: \(Int(initialState.heartRate)) BPM")
            print("   Zone: \(initialState.heartRateZone.rawValue)")
            return "preview-workout-id"
        },
        update: { activityId, newState in
            print("🔵 [Workout Preview] Updated: \(activityId)")
            print("   HR: \(Int(newState.heartRate)) BPM (\(newState.heartRatePercentage)%)")
        },
        stop: { activityId in
            print("🔴 [Workout Preview] Stopped: \(activityId)")
        }
    )
}

// MARK: - DependencyValues Extension

extension DependencyValues {
    public var workoutActivityClient: WorkoutActivityClient {
        get { self[WorkoutActivityClient.self] }
        set { self[WorkoutActivityClient.self] = newValue }
    }
}
