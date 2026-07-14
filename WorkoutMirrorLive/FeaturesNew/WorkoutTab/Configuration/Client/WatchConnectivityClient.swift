//
//  WatchConnectivityClient.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 17/09/2025.
//

import ComposableArchitecture
import HealthHub
import SharedModels
import Foundation

/// TCA dependency that bridges features with `WatchConnectivityManager`.
///
/// Provides a composable interface for managing the WatchConnectivity session,
/// sending workout events to Apple Watch, and receiving heart rate readings back.
public struct WatchConnectivityClient: Sendable {

    /// Activates the WatchConnectivity session.
    public var initializeWatchConnectivity: @Sendable () async -> Void

    /// Evaluates and returns the current connection status.
    public var checkWatchStatus: @Sendable () async -> WatchConnectivityStatus

    /// Deactivates the WatchConnectivity session.
    public var stopWatchConnectivity: @Sendable () async -> Void

    /// Sends a workout event to the paired Apple Watch.
    ///
    /// Uses `sendMessage` when reachable, falls back to `transferUserInfo`.
    public var sendWorkoutEvent: @Sendable (WatchWorkoutEvent) async -> Void

    /// A stream of incoming workout events received from the paired Apple Watch.
    ///
    /// Yields `WatchWorkoutEvent` values — primarily `.workoutSaved(uuid)` after Watch
    /// completes `finishWorkout()`. HR readings flow via HealthKit mirroring, NOT WC.
    public var incomingEventStream: @Sendable () -> AsyncStream<WatchWorkoutEvent>
}

// MARK: - Dependency Registration

public enum WatchConnectivityClientKey: DependencyKey {

    /// Live implementation backed by `WatchConnectivityManager`.
    public static let liveValue: WatchConnectivityClient = {
        
        @Dependency(\.watchConnectivityManager) var watchManager

        return WatchConnectivityClient(
            initializeWatchConnectivity: {
                print("🍎 WatchConnectivityClient: Initializing WatchConnectivity...")
                await watchManager.initializeWatchConnectivity()
            },
            checkWatchStatus: {
                print("🍎 WatchConnectivityClient: Checking watch status...")
                return await watchManager.checkConnectionStatus()
            },
            stopWatchConnectivity: {
                await watchManager.stopWatchConnectivity()
            },
            sendWorkoutEvent: { event in
                try? await watchManager.sendWorkoutEvent(event)
            },
            incomingEventStream: {
                watchManager.incomingWorkoutEventStream
            }
        )
    }()
}

// MARK: - DependencyValues

public extension DependencyValues {
    var watchConnectivityClient: WatchConnectivityClient {
        get { self[WatchConnectivityClientKey.self] }
        set { self[WatchConnectivityClientKey.self] = newValue }
    }
}
