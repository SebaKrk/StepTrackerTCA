//
//  SessionFeature+CancelID.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 2026-05-29.
//

import Foundation

/// Cancel identifiers used by `SessionFeature` long-running effects.
///
/// `nonisolated` so synthesized `Hashable` conformance is not main-actor-isolated under the
/// project's `defaultIsolation(MainActor.self)`. Without it, `cancellable(id:)` rejects the
/// identifier (its `some Hashable & Sendable` generic param requires nonisolated conformance).
/// Top-level (not in an extension) so sub-reducer extensions in separate files can reference
/// identifiers without `SessionFeature.` prefix. Matches convention used by other top-level
/// CancelID enums (`PhasePanelFeatureCancelID`, `SummaryFeatureCancelID`).
nonisolated enum SessionWatchCancelID: Hashable, Sendable {

    /// HKWorkoutSessionState stream (mirrored or iPhone-primary).
    /// Started by `sessionPhaseReducer` on `.session`, cancelled there on `.summary`.
    case sessionStateStream

    /// Stream listening for incoming Watch workout events.
    /// Started by `sessionPhaseReducer` on `.session`, cancelled in
    /// `controlsRoutingReducer` on end-of-workout transitions.
    case watchEventStream

    /// One-second clock effect that sends `workoutTick` to Watch.
    /// Started by `sessionPhaseReducer` on `.session` and re-started in
    /// `controlsRoutingReducer` on resume; cancelled on pause/end.
    case watchTickTimer

    /// Workout metrics stream (HR + calories).
    /// Started by `sessionPhaseReducer` on `.session`, cancelled there on `.summary`.
    case metricsStream

    /// Retry effect for `.workoutEnded` propagation. Currently no reducer starts it
    /// (HK-channel send replaced the WC retry mechanism), but the identifier is
    /// preserved for the `.cancel(...)` call in `controlsRoutingReducer` which runs
    /// defensively on Watch-initiated end.
    case workoutEndedRetry

    /// One-shot subscription to `mirroredSessionStartedStream` used in Watch-primary
    /// mode to transition from `.waitingForWatch` → `.countdown`. Auto-cancels itself
    /// after the first emit via `break` in the for-await loop. Started by
    /// `lifecycleReducer` via `subscribeMirroredSessionStarted`.
    case mirroredSessionSignal

    /// App Intent NotificationCenter observers (Pause/Resume/End from Live Activity).
    /// Active while sessionState == .session, cancelled on transition to .summary.
    /// Started by `sessionPhaseReducer`, cancelled there in summary branch.
    case intentPauseObserver
    case intentResumeObserver
    case intentEndObserver

    /// Mirroring-link connection status stream (IOS-00098-G, Watch-primary only).
    /// Started by `sessionPhaseReducer` on `.session`, cancelled on end transitions.
    case watchConnectionStream

    /// BLE HR-sensor connection-reason stream (out of range / device off).
    /// Started by `sessionPhaseReducer` on `.session` (iPhone-standalone only),
    /// cancelled on end transitions alongside `metricsStream`.
    case sensorConnectionStream

}
