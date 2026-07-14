//
//  TimerActivityClient.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 23/01/2026.
//

import ActivityKit
import ComposableArchitecture
import Foundation
import SharedModels

@DependencyClient
public struct TimerActivityClient: Sendable {
    
    /// Starts a new Live Activity for timer
    /// - Parameters:
    ///   - timerName: Name of the timer
    ///   - initialState: Initial content state with timer metrics
    /// - Returns: Activity ID that can be used to update or stop the activity
    public var start: @Sendable (
        _ timerName: String,
        _ initialState: TimerActivityAttributes.ContentState
    ) async throws -> String = { _, _ in "" }
    
    /// Updates the timer Live Activity with new metrics
    /// - Parameters:
    ///   - activityId: ID of the activity to update
    ///   - newState: New content state with updated metrics
    public var update: @Sendable (
        _ activityId: String,
        _ newState: TimerActivityAttributes.ContentState
    ) async throws -> Void
    
    /// Stops and dismisses the timer Live Activity
    /// - Parameter activityId: ID of the activity to stop
    public var stop: @Sendable (
        _ activityId: String
    ) async throws -> Void
}

// MARK: - DependencyKey

extension TimerActivityClient: DependencyKey {
    public static let liveValue = Self(
        start: { timerName, initialState in
            let attributes = TimerActivityAttributes(
                timerName: timerName,
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
            let activities = Activity<TimerActivityAttributes>.activities
            guard let activity = activities.first(where: { $0.id == activityId }) else {
                throw LiveActivityError.activityNotFound
            }
            
            await activity.update(
                .init(state: newState, staleDate: nil)
            )
        },
        stop: { activityId in
            let activities = Activity<TimerActivityAttributes>.activities
            guard let activity = activities.first(where: { $0.id == activityId }) else {
                throw LiveActivityError.activityNotFound
            }
            
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    )
    
    public static let previewValue = Self(
        start: { timerName, initialState in
            print("⏱️ [Timer Preview] Started: \(timerName)")
            print("   Initial HR: \(Int(initialState.heartRate)) BPM")
            print("   Running: \(initialState.isRunning)")
            return "preview-timer-id"
        },
        update: { activityId, newState in
            print("🔵 [Timer Preview] Updated: \(activityId)")
            print("   Running: \(newState.isRunning)")
            print("   Adj Start: \(newState.adjustedStartDate)")
        },
        stop: { activityId in
            print("🛑 [Timer Preview] Stopped: \(activityId)")
        }
    )
    
    public static let testValue = Self()
}

// MARK: - DependencyValues Extension

extension DependencyValues {
    public var timerActivityClient: TimerActivityClient {
        get { self[TimerActivityClient.self] }
        set { self[TimerActivityClient.self] = newValue }
    }
}
