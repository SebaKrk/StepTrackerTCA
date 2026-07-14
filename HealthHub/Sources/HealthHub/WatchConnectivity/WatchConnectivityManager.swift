//
//  WatchConnectivityManager.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 17/09/2025.
//

import SharedModels
import WatchConnectivity

/// Defines the interface for managing a WatchConnectivity session.
///
/// Abstracts over `WCSession` to allow dependency injection and testability.
/// Implementations are responsible for activating the session, tracking
/// connection status, and exchanging `WatchWorkoutEvent` messages with
/// the paired device.
public protocol WatchConnectivityManager: Sendable {

    /// Whether WatchConnectivity is supported on this device.
    var isSupported: Bool { get async }

    /// Whether an Apple Watch is currently paired. iOS only.
    var isPaired: Bool { get async }

    /// Whether the companion Watch app is installed. iOS only.
    var isWatchAppInstalled: Bool { get async }

    /// Whether the paired device is reachable for real-time communication.
    var isReachable: Bool { get async }

    /// The current connection status between iPhone and Watch.
    var currentStatus: WatchConnectivityStatus { get async }

    /// Activates the `WCSession` and begins monitoring connection status.
    func initializeWatchConnectivity() async

    /// Evaluates and returns the current connection status.
    func checkConnectionStatus() async -> WatchConnectivityStatus

    /// Deactivates the session and resets the connection status.
    func stopWatchConnectivity() async

    /// Sends a workout event to the paired device.
    ///
    /// Uses `sendMessage` when the device is reachable for immediate delivery,
    /// otherwise falls back to `transferUserInfo` for guaranteed background delivery.
    /// - Parameter event: The `WatchWorkoutEvent` to send.
    /// - Throws: `WatchConnectivityError.sessionNotActivated` if the session is not ready.
    func sendWorkoutEvent(_ event: WatchWorkoutEvent) async throws

    /// A stream of incoming workout events from the paired device.
    ///
    /// Yields events decoded from both `sendMessage` and `transferUserInfo` deliveries.
    var incomingWorkoutEventStream: AsyncStream<WatchWorkoutEvent> { get }
    
}
