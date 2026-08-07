//
//  TrainingManager.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 30/05/2025.
//

import HealthKit
import SharedModels

/// A protocol that manages HealthKit-based workout sessions.
///
/// This includes starting a workout, toggling pause/resume, ending the session,
/// and exposing real-time streams for workout metrics and session state.
///
public protocol TrainingManager: Sendable {
    
#if os(watchOS)
    /// The current HKLiveWorkoutBuilder instance used to collect live workout data.
    ///
    /// This is exposed for internal use and should not be modified externally.
    var builder: HKLiveWorkoutBuilder? { get }
#endif
    // MARK: - Workout Configuration
    
    /// Sets the workout type and initializes a new HealthKit session.
    ///
    /// - Parameter type: The workout activity type to be tracked.
    func setSelectedWorkout(_ type: HKWorkoutActivityType?)
    
    /// Sets the state of the summary view (shown at the end of a workout).
    ///
    /// - Parameter value: `true` to show the summary view, `false` to hide it.
    func setValueForSummaryView(_ value: Bool)
    
    // MARK: - Session Lifecycle
    
    var sessionState: HKWorkoutSessionState { get }
    
    /// Pauses or resumes the workout session depending on its current state.
    func togglePause()
    
    /// Ends the current workout session.
    func endWorkout()
    
    ///
    func startWorkout() async
    
    // MARK: - Streams

    /// A stream that emits live workout metrics, such as heart rate and calories burned.
    var workoutMetricsStream: AsyncStream<WorkoutMetrics> { get }

    /// A stream that emits the running state of the workout session.
    ///
    /// Emits `true` if the workout is currently running, otherwise `false`.
    func workoutSessionIsRunningStream() -> AsyncStream<Bool>

    /// A stream that emits `HKWorkoutSessionState` changes for the managed session.
    ///
    /// In Watch-primary mode this reflects the mirrored session state received
    /// from Apple Watch. In iPhone-standalone mode it reflects the local session.
    var workoutSessionStateStream: AsyncStream<HKWorkoutSessionState> { get }
    
    
    // MARK: - Workout Snapshot
    
    /// Returns the finalized `HKWorkout` object representing the completed workout session.
    ///
    /// - Returns: An optional `HKWorkout` instance. Returns `nil` if the workout has not ended yet.
    func getWorkout() -> HKWorkout?
    
    /// Returns the latest `WorkoutMetrics` collected during the session.
    ///
    /// Useful for generating summaries or displaying final statistics after the workout ends.
    /// - Returns: A `WorkoutMetrics` instance containing metrics such as duration, distance, and calories.
    func getWorkoutMetrics() -> WorkoutMetrics
    
    // MARK: - Platform Setup
    
    #if os(iOS)
    /// Sets up the handler to receive mirrored sessions from Apple Watch (iOS only)
    func setupRemoteSessionHandler()

    // (protocol helper type — see `WatchMirroringConnectionStatus` at the bottom of the file)

    /// Launches the Watch app and requests it to start a workout session of the given type.
    ///
    /// The Watch will create `HKWorkoutSession`, call `startMirroringToCompanionDevice()`,
    /// and iPhone will receive a mirrored session via `workoutSessionMirroringStartHandler`.
    func startWatchWorkout(
        workoutType: HKWorkoutActivityType,
        locationType: HKWorkoutSessionLocationType
    ) async throws

    /// Emits once when iPhone receives the mirrored session from Apple Watch.
    ///
    /// `SessionFeature` subscribes to this stream after calling `startWatchWorkout(...)` to
    /// know when to transition from `.waitingForWatch` UI state to `.countdown` (Apple
    /// Fitness-style startup flow). Replaces the previous "blind countdown" that ran in
    /// parallel with `startWatchApp` without knowing whether the Watch actually responded.
    var mirroredSessionStartedStream: AsyncStream<Void> { get }

    /// Multicast stream of the mirroring-link connection status (IOS-00098-G).
    ///
    /// `.lost` after `didDisconnectFromRemoteDeviceWithError` while the session is
    /// running/paused (a normal end-teardown disconnect does NOT emit), `.connected`
    /// when the system reconnect delivers a fresh mirrored session via the start
    /// handler. Drives the connection-lost banner, tick-send gating and End-button
    /// instruction alert in `SessionFeature`.
    var watchConnectionStatusStream: AsyncStream<WatchMirroringConnectionStatus> { get }

    /// Sends arbitrary data to the paired Watch through the HealthKit mirroring channel
    /// (`HKWorkoutSession.sendToRemoteWorkoutSession(data:)`).
    ///
    /// Used in Watch-primary mode for lifecycle events that need reliable delivery even
    /// when WatchConnectivity is unreachable (fixes the pre-existing iPhone-initiated End
    /// bug where `.workoutEnded` WC event was dropped if `reachable=false`).
    ///
    /// Returns `true` when HealthKit confirmed delivery to the mirroring channel;
    /// `false` when there is no mirrored session, the send failed, or timed out.
    /// Critical lifecycle events (iPhone-initiated End) MUST branch on the result.
    @discardableResult
    func sendDataToWatch(_ data: Data) async -> Bool

    /// Re-attaches a recovered `HKWorkoutSession` after iPhone app launch following a crash.
    ///
    /// Called from `AppDelegate.application(_:didFinishLaunchingWithOptions:)` via the
    /// always-try `recoverActiveWorkoutSession()` path.
    ///
    /// `HKLiveWorkoutBuilder` and `HKLiveWorkoutDataSource` do NOT survive recovery —
    /// implementations MUST rebuild both via `session.associatedWorkoutBuilder()` and a
    /// fresh `HKLiveWorkoutDataSource` initialized with `session.workoutConfiguration`.
    /// Without this rebuild, no further samples will be collected even though the session
    /// is technically alive.
    func recover(session: HKWorkoutSession)
    #endif

}

#if os(iOS)
/// Connection status of the HealthKit mirroring link with the Watch-primary session
/// (IOS-00098-G). Distinct from `HKWorkoutSessionState` — a lost link does NOT mean
/// the workout stopped; the Watch keeps measuring and the system auto-reconnects.
/// Declared next to the protocol (not in the implementation file) — the type is part of the
/// `watchConnectionStatusStream` contract.
public enum WatchMirroringConnectionStatus: Equatable, Sendable {
    case connected
    case lost
}
#endif
