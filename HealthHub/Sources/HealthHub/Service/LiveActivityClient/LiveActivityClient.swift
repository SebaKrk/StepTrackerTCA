//
//  LiveActivityClient.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 15/01/2026.
//

import ActivityKit
import ComposableArchitecture
import Foundation
import SharedModels

@DependencyClient
public struct LiveActivityClient: Sendable {
    
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

extension LiveActivityClient: DependencyKey {
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
            print("🟢 [LiveActivity Preview] Started: \(workoutName)")
            print("   Initial HR: \(Int(initialState.heartRate)) BPM")
            print("   Zone: \(initialState.heartRateZone.rawValue)")
            return "preview-activity-id"
        },
        update: { activityId, newState in
            print("🔵 [LiveActivity Preview] Updated: \(activityId)")
            print("   HR: \(Int(newState.heartRate)) BPM (\(newState.heartRatePercentage)%)")
            print("   Zone: \(newState.heartRateZone.rawValue)")
            print("   Energy: \(Int(newState.activeEnergy)) kcal")
        },
        stop: { activityId in
            print("🔴 [LiveActivity Preview] Stopped: \(activityId)")
        }
    )
    
    public static let testValue = Self()
}

// MARK: - DependencyValues Extension

extension DependencyValues {
    public var liveActivityClient: LiveActivityClient {
        get { self[LiveActivityClient.self] }
        set { self[LiveActivityClient.self] = newValue }
    }
}

// MARK: - Errors

enum LiveActivityError: Error, LocalizedError {
    case activityNotFound
    
    var errorDescription: String? {
        switch self {
        case .activityNotFound:
            return "Live Activity not found"
        }
    }
}
