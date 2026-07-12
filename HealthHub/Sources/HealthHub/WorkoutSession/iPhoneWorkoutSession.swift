//
//  iPhoneWorkoutSession.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 28/05/2026.
//

import Foundation
import HealthKit
import OSLog
import SharedModels

/// iPhone-primary workout session — native iOS 26 stack with BLE HR sensor support.
///
/// Wraps `HKWorkoutSession` + `HKLiveWorkoutBuilder` + `HKLiveWorkoutDataSource`. The data
/// source auto-pairs BLE HR sensors that the user has already paired in iOS Settings →
/// Bluetooth (Polar H10, Wahoo TICKR, Powerbeats Pro 2 etc.).
///
/// Conforms to ``WorkoutSession`` (SharedModels). Wrapped by `WorkoutSessionClient` and
/// orchestrated by `DefaultTrainingManager` in iPhone-standalone mode.
///
/// ## Lifecycle contract
///
/// - `prepare()` calls `HKWorkoutSession.prepare()` before any `start(at:)`. A 3 s
///   countdown in the UI between `prepare` and `start` lets slow straps complete their
///   pairing handshake.
/// - `end()` calls `HKWorkoutSession.end()` in `defer`, guaranteeing the session never
///   sticks in zombie state even if `endCollection`/`finishWorkout` throw.
/// - The single emit on the `workout` stream uses `builder.finishWorkout()` return value
///   directly, not `HKAnchoredObjectQueryDescriptor`. Reason: in iPhone-standalone mode
///   we own the builder and the call returns the finalized `HKWorkout` synchronously — no
///   need to poll. The anchored-query path is used on iPhone-side of Watch-primary
///   mirroring (no builder available there).
/// - `metrics`, `state`, `workout` are computed properties returning a fresh `AsyncStream`
///   per access. `yield()` broadcasts to every active continuation registered in
///   `[UUID: Continuation]` dictionaries; `onTermination` removes the consumer's entry.
///
/// ## Threading
///
/// Class is `NSObject` subclass (required for Apple delegate protocols) marked
/// `@unchecked Sendable`. All mutable state is guarded by per-stream `NSLock` instances.
/// HK delegate callbacks land on `HKHealthStore` queue; broadcasting is lock-then-copy
/// to avoid holding lock during user `yield()` work.
public final class iPhoneWorkoutSession: NSObject, @unchecked Sendable {

    // MARK: - Dependencies

    private let healthStore: HKHealthStore
    private let configuration: HKWorkoutConfiguration

    // MARK: - HK objects (created in prepare)

    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    // MARK: - Continuation registries (broadcasting)

    private let metricsLock = NSLock()
    private var metricsContinuations: [UUID: AsyncStream<WorkoutMetrics>.Continuation] = [:]

    private let stateLock = NSLock()
    private var stateContinuations: [UUID: AsyncStream<HKWorkoutSessionState>.Continuation] = [:]

    private let workoutLock = NSLock()
    private var workoutContinuations: [UUID: AsyncStream<HKWorkout>.Continuation] = [:]

    // MARK: - Aggregated metrics state

    /// Accumulator updated by `didCollectDataOf` callbacks before each broadcast.
    /// Guarded by `metricsLock` because `didCollectDataOf` may fire concurrently with reads.
    private var currentMetrics = WorkoutMetrics(averageHeartRate: 0, heartRate: 0, activeEnergy: 0)

    // MARK: - End idempotency

    /// Guards `end()` against concurrent double invocation (e.g. a double "End"
    /// tap) — a second `endCollection`/`finishWorkout` on the same builder
    /// corrupts the save and the workout is lost. First caller claims the flag,
    /// every later call is a logged no-op. Reset in `prepare()` (rule R7:
    /// session-specific state resets per workout).
    private let endClaimLock = NSLock()

    /// `true` once an `end()` call claimed the teardown — see `endClaimLock`.
    private var hasEnded = false

    // MARK: - Init

    public init(
        healthStore: HKHealthStore,
        configuration: HKWorkoutConfiguration
    ) {
        self.healthStore = healthStore
        self.configuration = configuration
        super.init()
    }

    // MARK: - Lifecycle

    public func prepare() async throws {
        let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
        session.delegate = self

        let builder = session.associatedWorkoutBuilder()
        builder.delegate = self
        builder.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore,
            workoutConfiguration: configuration
        )

        // Warmup HK + BLE sensor pairing. The 3 s countdown in UI uses this gap.
        session.prepare()

        self.session = session
        self.builder = builder
        endClaimLock.withLock { hasEnded = false }

        Logger.iPhoneWorkoutSession.info("prepare() — session created, builder attached, dataSource bound")
    }

    public func start(at date: Date) async throws {
        guard let session, let builder else {
            Logger.iPhoneWorkoutSession.error("start(at:) called before prepare()")
            throw iPhoneWorkoutSessionError.notPrepared
        }
        session.startActivity(with: date)
        try await builder.beginCollection(at: date)
        Logger.iPhoneWorkoutSession.info("start(at:) — activity started at \(date)")
    }

    public func pause() async throws {
        guard let session else { return }
        session.pause()
        Logger.iPhoneWorkoutSession.info("pause()")
    }

    public func resume() async throws {
        guard let session else { return }
        session.resume()
        Logger.iPhoneWorkoutSession.info("resume()")
    }

    public func end() async throws {
        // Claim-or-bail (see `endClaimLock`) — must happen BEFORE touching the
        // builder; a concurrent second call corrupts the save.
        let alreadyEnding = endClaimLock.withLock { () -> Bool in
            if hasEnded { return true }
            hasEnded = true
            return false
        }
        guard !alreadyEnding else {
            Logger.iPhoneWorkoutSession.notice("end() ignored — already ending (double End)")
            await WorkoutFileLogger.shared.log("[End] duplicate end() ignored — already ending")
            return
        }
        guard let session, let builder else {
            throw iPhoneWorkoutSessionError.notPrepared
        }

        // session.end() MUST be called even if builder operations throw, otherwise
        // HKWorkoutSession stays in zombie state and blocks the next workout.
        // workout-stream MUST also be finished — otherwise downstream cache tasks
        // (e.g. WorkoutModeRouter awaiting `workout` AsyncStream) hang forever.
        defer {
            session.end()
            finishWorkoutStream()
            Logger.iPhoneWorkoutSession.info("end() — session.end() invoked, workout stream finished")
        }

        let endDate = Date()
        do {
            try await builder.endCollection(at: endDate)
            let finalWorkout = try await builder.finishWorkout()
            if let workout = finalWorkout {
                broadcastWorkout(workout)
                Logger.iPhoneWorkoutSession.info("finishWorkout — HKWorkout uuid=\(workout.uuid.uuidString, privacy: .public)")
            } else {
                Logger.iPhoneWorkoutSession.error("finishWorkout returned nil — no HKWorkout to broadcast")
            }
        } catch {
            Logger.iPhoneWorkoutSession.error("endCollection/finishWorkout failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    /// Finishes all `workout` stream continuations without yielding. Called from `end()`
    /// in `defer` so cache subscribers (e.g. WorkoutModeRouter) always see termination
    /// even if `finishWorkout()` returned nil or threw.
    private func finishWorkoutStream() {
        workoutLock.lock()
        let continuations = Array(workoutContinuations.values)
        workoutContinuations.removeAll()
        workoutLock.unlock()
        for continuation in continuations {
            continuation.finish()
        }
    }

    public func reattach(to recoveredSession: HKWorkoutSession) async throws {
        recoveredSession.delegate = self

        let builder = recoveredSession.associatedWorkoutBuilder()
        builder.delegate = self
        builder.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore,
            workoutConfiguration: recoveredSession.workoutConfiguration
        )

        self.session = recoveredSession
        self.builder = builder
        // Crash recovery is the second session entry point — the end claim must
        // reset here just like in `prepare()` (rule R7), or `end()` on the
        // recovered session could silently no-op.
        endClaimLock.withLock { hasEnded = false }

        Logger.iPhoneWorkoutSession.info("reattach — session+builder restored (state=\(recoveredSession.state.rawValue))")
    }

    // MARK: - Streams (computed, fresh per access)

    public var metrics: AsyncStream<WorkoutMetrics> {
        AsyncStream { continuation in
            let id = UUID()
            metricsLock.lock()
            metricsContinuations[id] = continuation
            metricsLock.unlock()

            continuation.onTermination = { [weak self] _ in
                self?.metricsLock.lock()
                self?.metricsContinuations.removeValue(forKey: id)
                self?.metricsLock.unlock()
            }
        }
    }

    public var state: AsyncStream<HKWorkoutSessionState> {
        AsyncStream { continuation in
            let id = UUID()
            stateLock.lock()
            stateContinuations[id] = continuation
            stateLock.unlock()

            continuation.onTermination = { [weak self] _ in
                self?.stateLock.lock()
                self?.stateContinuations.removeValue(forKey: id)
                self?.stateLock.unlock()
            }
        }
    }

    public var workout: AsyncStream<HKWorkout> {
        AsyncStream { continuation in
            let id = UUID()
            workoutLock.lock()
            workoutContinuations[id] = continuation
            workoutLock.unlock()

            continuation.onTermination = { [weak self] _ in
                self?.workoutLock.lock()
                self?.workoutContinuations.removeValue(forKey: id)
                self?.workoutLock.unlock()
            }
        }
    }

    // MARK: - Broadcasting

    private func broadcastMetrics(_ metrics: WorkoutMetrics) {
        metricsLock.lock()
        let continuations = Array(metricsContinuations.values)
        metricsLock.unlock()
        for continuation in continuations {
            continuation.yield(metrics)
        }
    }

    private func broadcastState(_ state: HKWorkoutSessionState) {
        stateLock.lock()
        let continuations = Array(stateContinuations.values)
        stateLock.unlock()
        for continuation in continuations {
            continuation.yield(state)
        }
    }

    private func broadcastWorkout(_ workout: HKWorkout) {
        workoutLock.lock()
        let continuations = Array(workoutContinuations.values)
        workoutLock.unlock()
        for continuation in continuations {
            continuation.yield(workout)
            continuation.finish()
        }
    }
}

// MARK: - WorkoutSession conformance

extension iPhoneWorkoutSession: RecoverableWorkoutSession {}

// MARK: - HKWorkoutSessionDelegate

extension iPhoneWorkoutSession: HKWorkoutSessionDelegate {

    public func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        Logger.iPhoneWorkoutSession.info("state \(fromState.rawValue) → \(toState.rawValue)")
        broadcastState(toState)
    }

    public func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {
        Logger.iPhoneWorkoutSession.error("session didFailWithError: \(error.localizedDescription, privacy: .public)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate

extension iPhoneWorkoutSession: HKLiveWorkoutBuilderDelegate {

    public func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Builder-level events (pause/resume markers, lap, segment) — surfaced through
        // session delegate's didChangeTo callback, so we don't double-broadcast here.
    }

    public func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        metricsLock.lock()
        var working = currentMetrics
        metricsLock.unlock()

        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            let statistics = workoutBuilder.statistics(for: quantityType)

            switch quantityType {
            case HKQuantityType(.heartRate):
                let unit = HKUnit.count().unitDivided(by: .minute())
                if let mostRecent = statistics?.mostRecentQuantity()?.doubleValue(for: unit) {
                    working.heartRate = mostRecent
                }
                if let average = statistics?.averageQuantity()?.doubleValue(for: unit) {
                    working.averageHeartRate = average
                }
                // Freshness (IOS-00100-A): `mostRecentQuantity()` repeats the last
                // value forever after the BLE strap drops out of range — only the
                // sample's own timestamp lets consumers tell live from stale.
                if let sampleDate = statistics?.mostRecentQuantityDateInterval()?.end {
                    working.heartRateSampleDate = sampleDate
                }

            case HKQuantityType(.activeEnergyBurned):
                if let sum = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) {
                    working.activeEnergy = sum
                }

            default:
                continue
            }
        }

        metricsLock.lock()
        currentMetrics = working
        metricsLock.unlock()

        broadcastMetrics(working)
    }
}

// MARK: - Errors

public enum iPhoneWorkoutSessionError: Error, Sendable {
    case notPrepared
}
