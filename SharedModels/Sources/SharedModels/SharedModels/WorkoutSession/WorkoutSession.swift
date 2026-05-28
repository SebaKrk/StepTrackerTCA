//
//  WorkoutSession.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 28/05/2026.
//

import Foundation
import HealthKit

/// Lifecycle abstraction for an active workout session under iOS 26 Hybrid architecture.
///
/// Two implementations are consumed via `@Dependency(\.workoutSessionClient)`:
/// - `iPhoneWorkoutSession` (iOS 26+) — Tor B (iPhone-primary, BLE HR sensor)
/// - `WatchWorkoutSession` (watchOS 10+) — Tor A (Watch-primary, mirroring)
///
/// ## Contracts (R1, R4, R5, R6 from `WorkoutMirrorLive/CLAUDE.md`)
///
/// **R1** — `prepare()` MUST be called before `start(at:)`. Gives the HR sensor (Watch wrist
/// or BLE strap) time to warmup. Skipping causes iOS 26 mirroring disconnects
/// (Apple Developer Forums #804276 / FB20723311).
///
/// **R4** — `end()` implementation MUST call the underlying `HKWorkoutSession.end()` even
/// if `builder.endCollection(at:)` throws, otherwise the session stays in zombie state
/// and blocks the next workout.
///
/// **R5** — `workout` stream MUST be backed by `HKAnchoredObjectQueryDescriptor.results(for:)`
/// (iOS 15.4+), push-based AsyncSequence — NOT polling. Single emit when the session ends
/// and the `HKWorkout` lands in the HealthKit store.
///
/// **R6** — `metrics`, `state`, `workout` MUST be implemented as **computed properties** that
/// return a fresh `AsyncStream` on each access. `AsyncStream` only supports one iterator;
/// a stored stream paired with TCA cancellation results in the next `for await` receiving
/// nothing.
public protocol WorkoutSession: Sendable {

    // MARK: - Lifecycle

    /// Authorize HealthKit + warmup sensor (BLE pair / Watch wrist). Call before `start(at:)`.
    /// 3-second countdown in the UI after `prepare()` gives slow straps time for pairing handshake.
    func prepare() async throws

    /// Begin collecting samples. `date` sets the underlying `HKWorkoutSession` activity start timestamp.
    func start(at date: Date) async throws

    /// Pause collection. HealthKit automatically syncs the paused state between iPhone and Watch in Tor A.
    func pause() async throws

    /// Resume collection. Counterpart to `pause()`.
    func resume() async throws

    /// End session and finalize the workout. See R4 for the mandatory `session.end()` invariant.
    func end() async throws

    // MARK: - Streams

    /// Live workout metrics (HR, calories, distance) emitted from `HKLiveWorkoutBuilder` delegate.
    /// Typical cadence: ~1 Hz for HR, event-driven for calories and distance.
    var metrics: AsyncStream<WorkoutMetrics> { get }

    /// Session state transitions: `.prepared` → `.running` → `.paused` → `.ended`.
    /// In Tor A reflects the mirrored Watch session; in Tor B reflects the local iPhone session.
    var state: AsyncStream<HKWorkoutSessionState> { get }

    /// Final `HKWorkout` emitted exactly once after the session ends and the sample lands in HealthKit.
    /// Push-based via `HKAnchoredObjectQueryDescriptor.results(for:)` per R5 — no polling.
    var workout: AsyncStream<HKWorkout> { get }
}
