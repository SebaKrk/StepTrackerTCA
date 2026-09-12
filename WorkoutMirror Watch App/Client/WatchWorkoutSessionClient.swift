//
//  WatchWorkoutSessionClient.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Sciuba on 05/04/2026.
//

import ComposableArchitecture
import CoreLocation
import HealthKit
import Foundation
import OSLog
import SharedModels

/// TCA dependency that manages the primary `HKWorkoutSession` on Apple Watch.
///
/// **Watch-primary pattern (WWDC23/25):** Watch owns the `HKWorkoutSession` and calls
/// `startMirroringToCompanionDevice()` so iPhone receives a mirrored session via
/// `workoutSessionMirroringStartHandler`. Watch saves the canonical `HKWorkout`.
///
/// HR readings are forwarded to iPhone via `sendToRemoteWorkoutSession` (HealthKit
/// mirroring channel) — **not** WatchConnectivity. Pause/resume state propagates
/// automatically through HealthKit; no manual signalling needed.
struct WatchWorkoutSessionClient: Sendable {

    /// Starts a `HKWorkoutSession` on Watch for accurate HR collection and
    /// returns an `AsyncStream<Double>` of live BPM readings. `locationType`
    /// comes from the iPhone's configuration (`.unknown` on paths that don't
    /// carry one — the manager falls back to its activity-type heuristic).
    var startSession: @Sendable (_ activityType: HKWorkoutActivityType, _ locationType: HKWorkoutSessionLocationType) async -> AsyncStream<Double>

    /// Ends the active session: stops collection, discards the builder (no HKWorkout saved), ends the session.
    var endSession: @Sendable () async -> Void

    /// Sends a `WorkoutMetrics` snapshot to the paired iPhone via HealthKit's native mirroring channel
    /// (`sendToRemoteWorkoutSession`). Only used in Watch-primary mode for HR transfer (R2).
    var sendHRToRemote: @Sendable (Double, Date) async -> Void

    /// Pauses or resumes the active `HKWorkoutSession` on Watch. HealthKit mirroring automatically
    /// propagates the state change to iPhone's mirrored session, triggering
    /// `HKWorkoutSessionDelegate.workoutSession(_:didChangeTo:from:date:)` on the iPhone side.
    var togglePause: @Sendable () async -> Void

    /// Emits `.paused` / `.running` state changes from the Watch `HKWorkoutSession`.
    ///
    /// Required so `HRMirrorFeature` can sync `isPaused` when iPhone initiates a pause
    /// via the mirrored session — in that case HealthKit propagates to Watch's primary
    /// session but `HRMirrorFeature` has no other way to observe the change.
    var sessionStateStream: @Sendable () -> AsyncStream<HKWorkoutSessionState>

    /// Checks HealthKit for an active `HKWorkoutSession` left over from the previous app run
    /// (crash, battery death, force-quit) and finalizes it immediately through the normal
    /// end flow — the workout is always saved, never silently lost. Wraps
    /// `HKHealthStore.recoverActiveWorkoutSession()` (watchOS 9+).
    ///
    /// Single-flight and cached once settled, so concurrent triggers (launch check,
    /// `handleActiveWorkoutRecovery`, the gate inside `startSession`) share one recovery
    /// pass; transient failures are retried on the next trigger. Returns a snapshot of
    /// the recovered session for logging — delivered to exactly one caller — or `nil`
    /// when there was nothing to recover; the normal start flow is then unaffected.
    var recoverStuckSession: @Sendable () async -> StuckSession?

    /// Stream of `WatchWorkoutEvent`s received from iPhone via the HealthKit mirroring
    /// channel (`didReceiveDataFromRemoteWorkoutSession`). Complementary path to
    /// `WatchConnectivityClientAW.incomingEventStream` — reliable when WC is unreachable.
    var remoteEventStream: @Sendable () -> AsyncStream<WatchWorkoutEvent>

    /// Returns the `HKWorkout.uuid` of the most recently saved workout (set in both `end()`
    /// primary path and `.ended` safety-net path), and clears it after read.
    /// One-shot — second call after save returns nil. Used by `HRMirrorFeature.stop` to
    /// include UUID in the `.workoutSaved` event so iPhone can fetch the exact workout.
    var consumeLastSavedWorkoutUUID: @Sendable () async -> UUID?

    /// Returns a `WatchWorkoutSummary` built from the most recently saved workout
    /// (duration, kcal, avg HR — straight from the `finishWorkout()` return value),
    /// and clears it after read. One-shot, same semantics as `consumeLastSavedWorkoutUUID`.
    /// `nil` when the save failed or `finishWorkout()` returned no workout (IOS-00098-D).
    var consumeLastSavedWorkoutSummary: @Sendable () async -> WatchWorkoutSummary?
}

// MARK: - Dependency

extension DependencyValues {
    var watchWorkoutSessionClient: WatchWorkoutSessionClient {
        get { self[WatchWorkoutSessionClientKey.self] }
        set { self[WatchWorkoutSessionClientKey.self] = newValue }
    }
}

private enum WatchWorkoutSessionClientKey: DependencyKey {

    static let liveValue: WatchWorkoutSessionClient = {
        let manager = WatchWorkoutSessionManager()
        return WatchWorkoutSessionClient(
            startSession: { activityType, locationType in
                await manager.start(activityType: activityType, locationType: locationType)
            },
            endSession: {
                await manager.end()
            },
            sendHRToRemote: { bpm, date in
                await manager.sendHRToRemote(bpm: bpm, date: date)
            },
            togglePause: {
                await manager.togglePause()
            },
            sessionStateStream: {
                manager.sessionStateStream()
            },
            recoverStuckSession: {
                await manager.recoverAndFinalizeStuckSession()
            },
            remoteEventStream: {
                manager.remoteEventStream()
            },
            consumeLastSavedWorkoutUUID: {
                await manager.consumeLastSavedWorkoutUUID()
            },
            consumeLastSavedWorkoutSummary: {
                await manager.consumeLastSavedWorkoutSummary()
            }
        )
    }()
}

// MARK: - WatchWorkoutSessionManager

/// Internal actor that owns `HKWorkoutSession` and `HKLiveWorkoutBuilder` on watchOS.
private final class WatchWorkoutSessionManager: NSObject, @unchecked Sendable {

    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var hrContinuation: AsyncStream<Double>.Continuation?
    private var stateContinuation: AsyncStream<HKWorkoutSessionState>.Continuation?

    /// Continuation feeding `remoteEventStream()`. Yielded from
    /// `didReceiveDataFromRemoteWorkoutSession` after decoding each `Data` as a
    /// `WatchWorkoutEvent`.
    private var remoteEventContinuation: AsyncStream<WatchWorkoutEvent>.Continuation?

    /// Resolved by `HKWorkoutSessionDelegate` when session transitions to `.stopped`.
    /// Used to bridge the async gap between `stopActivity()` and the delegate callback.
    private var sessionStoppedContinuation: CheckedContinuation<Void, Never>?

    /// Guards against calling `finishWorkout()` twice — once from the explicit `end()` call
    /// and once from the `.ended` safety-net handler in the session delegate.
    private var workoutFinished = false

    // MARK: - Ride tracking (distance activities)

    /// GPS + route pipeline — Watch owns the session in Watch-primary mode, so
    /// the Watch records the route. `nil` for stationary workouts.
    private var routeRecorder: WorkoutRouteRecorder?

    /// Same accumulator as iPhone-standalone (`RideMetricsAccumulator` in
    /// SharedModels) — identical rolling-window math on both workout paths.
    /// `rideLock`-guarded: the GPS task and HK callbacks race.
    private var rideMetrics = RideMetricsAccumulator()
    private let rideLock = NSLock()

    /// Gates ride fields in the outgoing payload — non-distance workouts keep
    /// sending the legacy HR-only shape (old iPhones decode it unchanged).
    private var isDistanceActivity = false

    /// Consumes `routeRecorder.locations` into `rideMetrics`.
    private var locationsTask: Task<Void, Never>?

    /// UUID of the most recently saved HKWorkout. Set in both `end()` primary path and
    /// `.ended` safety-net path right after `builder.finishWorkout()` returns. Consumed
    /// (read + cleared) by `HRMirrorFeature` so it can ship UUID in `.workoutSaved` event.
    private var lastSavedWorkoutUUID: UUID?

    /// Summary snapshot of the most recently saved HKWorkout — set alongside
    /// `lastSavedWorkoutUUID` in both save paths. Consumed by `HRMirrorFeature`
    /// to feed the Watch mini-summary screen (IOS-00098-D).
    private var lastSavedWorkoutSummary: WatchWorkoutSummary?

    /// Returns the UUID set during the most recent save, then clears it.
    func consumeLastSavedWorkoutUUID() async -> UUID? {
        let uuid = lastSavedWorkoutUUID
        lastSavedWorkoutUUID = nil
        return uuid
    }

    /// Returns the summary snapshot from the most recent save, then clears it.
    func consumeLastSavedWorkoutSummary() async -> WatchWorkoutSummary? {
        let summary = lastSavedWorkoutSummary
        lastSavedWorkoutSummary = nil
        return summary
    }

    /// Maps a finished `HKWorkout` to the mini-summary snapshot. Reads statistics
    /// off the in-memory workout — no HealthKit query (Apple iOS 26 sample pattern).
    private func makeSummary(from workout: HKWorkout?) -> WatchWorkoutSummary? {
        guard let workout else { return nil }
        let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
        return WatchWorkoutSummary(
            duration: workout.duration,
            activeEnergyKcal: workout.statistics(for: HKQuantityType(.activeEnergyBurned))?
                .sumQuantity()?
                .doubleValue(for: .kilocalorie()) ?? 0,
            averageHeartRate: workout.statistics(for: HKQuantityType(.heartRate))?
                .averageQuantity()?
                .doubleValue(for: heartRateUnit) ?? 0
        )
    }

    /// Returns a stream of `.paused` / `.running` states from the Watch session delegate.
    ///
    /// `HRMirrorFeature` subscribes to this in `.start` so it can sync `isPaused`
    /// when iPhone initiates a pause via the mirrored session.
    func sessionStateStream() -> AsyncStream<HKWorkoutSessionState> {
        let (stream, continuation) = AsyncStream.makeStream(of: HKWorkoutSessionState.self)
        stateContinuation?.finish()
        stateContinuation = continuation
        return stream
    }

    /// Stream of `WatchWorkoutEvent`s received from iPhone via HK mirroring channel.
    /// Single-subscriber semantics matching `sessionStateStream` (latest subscriber wins).
    func remoteEventStream() -> AsyncStream<WatchWorkoutEvent> {
        let (stream, continuation) = AsyncStream.makeStream(of: WatchWorkoutEvent.self)
        remoteEventContinuation?.finish()
        remoteEventContinuation = continuation
        return stream
    }

    func start(
        activityType: HKWorkoutActivityType,
        locationType: HKWorkoutSessionLocationType
    ) async -> AsyncStream<Double> {
        // Every start is gated behind the single-flight recovery — this covers ALL entry
        // points (configuration stream, WC `.workoutStarted` fallback, remote events), not
        // just the sequenced one in AppFeatureAW. Without it, recovery's end() and this
        // start() race over `session`/`builder`/`workoutFinished` (last-writer-wins), and
        // its defer would finish the hrContinuation assigned below. Settled results are
        // cached, so the common no-recovery case returns immediately.
        _ = await recoverAndFinalizeStuckSession()

        let (stream, continuation) = AsyncStream.makeStream(
            of: Double.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        hrContinuation = continuation

        // Pre-condition diagnostics: detect if a previous session leaks into new start()
        // (the "Watch timer not running after iPhone restart" bug — a stale session
        // could bypass startActivity assumptions and reuse a stopped builder).
        let existingState = session?.state.description ?? "nil"
        let existingElapsed = builder?.elapsedTime ?? 0
        if session != nil {
            Logger.watchSession.error("start() — WARNING: existing session not nil, state=\(existingState), elapsed=\(existingElapsed)s")
            await WorkoutFileLogger.shared.log("[Start] WARNING — existing session=\(existingState), elapsed=\(existingElapsed)s (possible REUSE)")
        } else {
            await WorkoutFileLogger.shared.log("[Start] pre-condition OK: no existing session")
        }

        // Per-workout state reset (R7). Without it, `workoutFinished` left true by the
        // previous save makes end() SKIP finishWorkout() for every subsequent workout
        // in the same app session — no HKWorkout, no `.workoutSaved` UUID, no summary.
        // watchOS keeps the app resident between workouts, so this hit workout #2+.
        workoutFinished = false
        lastSavedWorkoutUUID = nil
        lastSavedWorkoutSummary = nil
        isDistanceActivity = activityType.collectsDistance
        rideLock.withLock { rideMetrics = RideMetricsAccumulator() }

        let config = HKWorkoutConfiguration()
        config.activityType = activityType
        // Trust the location the iPhone specified (treadmill = .running + .indoor);
        // fall back to the legacy heuristic on paths that don't carry one
        // (WC `.workoutStarted` fallback yields `.unknown`).
        let resolvedLocation: HKWorkoutSessionLocationType
        if locationType == .indoor || locationType == .outdoor {
            resolvedLocation = locationType
        } else {
            resolvedLocation = activityType.collectsDistance ? .outdoor : .indoor
        }
        config.locationType = resolvedLocation

        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            builder = session?.associatedWorkoutBuilder()
            session?.delegate = self
            builder?.delegate = self
            let dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: config
            )
            if !activityType.collectsDistance {
                // Stationary workouts must not record distance — arm swings and
                // steps between stations otherwise become the headline metric in
                // Apple Fitness. Same gate as `iPhoneWorkoutSession.makeDataSource`.
                dataSource.disableCollection(for: HKQuantityType(.distanceWalkingRunning))
                dataSource.disableCollection(for: HKQuantityType(.distanceCycling))
            }
            builder?.dataSource = dataSource

            // `prepare()` MUST be called before `startMirroringToCompanionDevice()`.
            // Without it mirroring disconnects on iOS 26.0.1+ (Apple Developer Forums
            // #804276, radar FB20723311). prepare() warms up the HR sensor pipeline and
            // primes the session for the iPhone-side mirror to attach cleanly.
            session?.prepare()

            let start = Date()
            session?.startActivity(with: start)
            let stateAfterStart = session?.state.description ?? "nil"
            Logger.watchSession.info("start() — session.state after startActivity: \(stateAfterStart)")
            await WorkoutFileLogger.shared.log("[Start] startActivity at \(start), session.state=\(stateAfterStart)")
            try await builder?.beginCollection(at: start)

            do {
                try await session?.startMirroringToCompanionDevice()
                Logger.watchSession.info("mirroring started → iPhone should receive mirrored session")
            } catch {
#if targetEnvironment(simulator)
                Logger.watchSession.debug("Simulator: mirroring not available (expected)")
#else
                Logger.watchSession.error("startMirroringToCompanionDevice failed: \(error.localizedDescription)")
#endif
            }

            // GPS only outdoors — a treadmill run keeps the accumulator (pace from
            // HealthKit distance deltas) but must not record a route.
            if isDistanceActivity && resolvedLocation == .outdoor {
                startRideTracking()
            }
        } catch {
            Logger.watchSession.error("start() failed to create HKWorkoutSession: \(error)")
            continuation.finish()
        }

        return stream
    }

    /// GPS pipeline (Watch-primary): silent route capture + live speed samples.
    /// The accumulated values ride along the next `sendHRToRemote` payload —
    /// no separate send; the HR cadence is enough for the iPhone tile.
    private func startRideTracking() {
        let recorder = WorkoutRouteRecorder(healthStore: healthStore)
        routeRecorder = recorder
        recorder.start()
        locationsTask?.cancel()
        locationsTask = Task { [weak self] in
            for await location in recorder.locations {
                guard let self else { return }
                self.rideLock.withLock {
                    self.rideMetrics.recordLocationSpeed(location.speed, at: location.timestamp)
                }
            }
        }
        Logger.watchSession.info("ride tracking started — GPS + route capture active")
    }

    func end() async {
        defer {
            hrContinuation?.finish()
            hrContinuation = nil
            locationsTask?.cancel()
            locationsTask = nil
            routeRecorder?.stop()
            routeRecorder = nil
            session = nil
            builder = nil
        }

        guard let session, let builder else {
            Logger.watchSession.info("end() — session/builder already nil, skipping")
            await WorkoutFileLogger.shared.log("[End] session/builder nil — skipping")
            return
        }

        Logger.watchSession.info("end() ▶ 1/3 stopActivityAndWait — sessionState=\(session.state.description)")
        await WorkoutFileLogger.shared.log("[End] 1/3 stopActivityAndWait — sessionState=\(session.state.description)")
        await stopActivityAndWait(session)
        Logger.watchSession.info("end() ✓ 1/3 session stopped")
        await WorkoutFileLogger.shared.log("[End] 1/3 stopActivityAndWait returned, sessionState=\(session.state.description)")

        Logger.watchSession.info("end() ▶ 2/3 endCollection")
        do {
            try await builder.endCollection(at: .now)
            Logger.watchSession.info("end() ✓ 2/3 endCollection OK")
            await WorkoutFileLogger.shared.log("[End] 2/3 endCollection OK")
        } catch {
            Logger.watchSession.error("end() endCollection failed: \(error)")
            await WorkoutFileLogger.shared.log("[End] 2/3 endCollection FAILED: \(error.localizedDescription)")
        }

        // Watch-primary: Watch owns the canonical HKWorkout.
        // workoutFinished guards against double-save (race with .ended safety-net handler).
        Logger.watchSession.info("end() — workoutFinished=\(self.workoutFinished) before finishWorkout check")
        if !workoutFinished {
            workoutFinished = true
            Logger.watchSession.info("end() ▶ 2/3 finishWorkout() — saving to HealthKit")
            do {
                let workout = try await builder.finishWorkout()
                lastSavedWorkoutUUID = workout?.uuid
                lastSavedWorkoutSummary = makeSummary(from: workout)
                if let workout {
                    await routeRecorder?.finishRoute(for: workout)
                }
                Logger.watchSession.info("end() ✓ workout saved to HealthKit (uuid=\(workout?.uuid.uuidString ?? "nil"))")
                await WorkoutFileLogger.shared.log("WATCH WORKOUT SAVED (uuid=\(workout?.uuid.uuidString ?? "nil"))")
            } catch {
                // Reset flag so .ended safety-net can recover the save.
                // Without reset: failed finishWorkout() in primary path = workout LOST forever.
                workoutFinished = false
                Logger.watchSession.error("end() finishWorkout failed: \(error) — flag reset for safety-net retry")
                await WorkoutFileLogger.shared.log("[End] finishWorkout FAILED: \(error.localizedDescription) — flag reset")
            }
        } else {
            Logger.watchSession.notice("end() — skipped finishWorkout (already saved by .ended safety-net)")
            await WorkoutFileLogger.shared.log("WATCH WORKOUT — skipped (saved by safety-net)")
        }

        Logger.watchSession.info("end() ▶ 3/3 session.end()")
        session.end()
        Logger.watchSession.info("end() ✓ done")
        await WorkoutFileLogger.shared.log("[End] DONE — session.end() returned")
    }

    /// Encodes `bpm` as a `WorkoutMetrics` JSON payload and sends it to iPhone via
    /// HealthKit's native mirroring channel (`sendToRemoteWorkoutSession`).
    ///
    /// iPhone's `DefaultTrainingManager.processReceivedWatchData(_:)` decodes the payload
    /// and yields it into `workoutMetricsContinuation`, making it available via `metricsStream`.
    func sendHRToRemote(bpm: Double, date: Date) async {
        guard let session else { return }

        let energy: Double = {
            guard let builder else { return 0 }
            let energyType = HKQuantityType(.activeEnergyBurned)
            return builder.statistics(for: energyType)?
                .sumQuantity()?
                .doubleValue(for: .kilocalorie()) ?? 0
        }()

        let avgHR: Double = {
            guard let builder else { return 0 }
            let hrType = HKQuantityType(.heartRate)
            let unit = HKUnit.count().unitDivided(by: .minute())
            return builder.statistics(for: hrType)?
                .averageQuantity()?
                .doubleValue(for: unit) ?? 0
        }()

        var metrics = WorkoutMetrics(averageHeartRate: avgHR, heartRate: bpm, activeEnergy: energy)
        if isDistanceActivity {
            // Ride fields are optional in the payload — an older iPhone app
            // simply ignores the extra keys (same back-compat rule as
            // `heartRateSampleDate`).
            let elapsed = builder?.elapsedTime ?? 0
            metrics = rideLock.withLock { rideMetrics.apply(to: metrics, elapsedTime: elapsed, at: Date()) }
        }
        guard let data = try? JSONEncoder().encode(metrics) else {
            Logger.watchSession.error("sendHRToRemote — failed to encode WorkoutMetrics")
            return
        }
        do {
            // Guarded variant (SharedModels) — hard timeout against Apple bug #769355
            // where the native async send never resumes.
            try await session.sendToRemoteWorkoutSession(data: data, timeout: 3)
        } catch {
            Logger.watchSession.error("sendToRemoteWorkoutSession failed: \(error.localizedDescription)")
        }
    }

    /// Pauses or resumes the active `HKWorkoutSession` directly on Watch.
    /// HealthKit mirroring automatically propagates the state change to iPhone.
    func togglePause() async {
        guard let session else { return }
        switch session.state {
        case .running:
            session.pause()
            Logger.watchSession.info("togglePause → pausing (was running)")
        case .paused:
            session.resume()
            Logger.watchSession.info("togglePause → resuming (was paused)")
        default:
            Logger.watchSession.notice("togglePause — unexpected state: \(session.state.rawValue)")
        }
    }

    /// Resumes the pending `stopActivityAndWait` continuation exactly once.
    /// Callers: delegate `.stopped`/`.ended` transitions, `didFailWithError`, and the timeout.
    private func resumeSessionStopped() {
        sessionStoppedContinuation?.resume()
        sessionStoppedContinuation = nil
    }

    /// Calls `session.stopActivity()` and suspends until the delegate confirms `.stopped`.
    ///
    /// If the session is already stopped or ended (e.g. crash recovery), skips immediately
    /// to avoid hanging on a continuation that will never be resumed.
    ///
    /// Bounded wait: a recovered zombie session may never report `.stopped` — it can jump
    /// straight to `.ended` or die via `didFailWithError` (both resume the continuation),
    /// or deliver no callback at all (the timeout backstops that). On timeout the end flow
    /// proceeds; R4 still guarantees `session.end()` runs.
    private func stopActivityAndWait(_ session: HKWorkoutSession) async {
        guard session.state == .running || session.state == .paused else {
            Logger.watchSession.info("stopActivityAndWait — skipped (state=\(session.state.rawValue) not running/paused)")
            return
        }
        Logger.watchSession.info("stopActivityAndWait — calling stopActivity(), awaiting delegate .stopped")
        let timeout = Task { [self] in
            try? await Task.sleep(for: .seconds(10))
            guard !Task.isCancelled else { return }
            Logger.watchSession.error("stopActivityAndWait — no delegate callback within 10 s, proceeding with end flow")
            await WorkoutFileLogger.shared.log("[End] stopActivityAndWait TIMED OUT — proceeding")
            resumeSessionStopped()
        }
        await withCheckedContinuation { continuation in
            sessionStoppedContinuation = continuation
            session.stopActivity(with: .now)
        }
        timeout.cancel()
        Logger.watchSession.info("stopActivityAndWait — wait finished (stopped/ended/failed/timeout)")
    }

    /// Single-flight guard for `recoverAndFinalizeStuckSession()`: the launch check,
    /// `handleActiveWorkoutRecovery` and the `start()` gate can race at process start,
    /// and only one caller may drive `end()`. A settled result (recovered / nothing to
    /// recover) is cached for the process lifetime — a new stuck session cannot appear
    /// without this process dying first. A retryable result (transient HK error, live
    /// session in the way) clears the cache so the next trigger tries again.
    private var recoveryTask: Task<RecoveryResult, Never>?
    private let recoveryLock = NSLock()

    /// Snapshot already handed to a caller — later callers get `nil`, so log-only side
    /// effects (`.stuckSessionRecovered`, log transfer) fire once per recovered session.
    private var recoverySnapshotDelivered = false

    /// Outcome of one recovery pass. `retryable` separates transient conditions from
    /// settled ones — only settled results may stay cached in `recoveryTask`.
    private struct RecoveryResult {
        let snapshot: StuckSession?
        let retryable: Bool
    }

    /// Result of a single `recoverActiveWorkoutSession` query.
    private enum RecoveryOutcome {
        case recovered(StuckSession)
        case nothingToRecover
        /// The HK query threw — e.g. HealthKit not ready on an early background relaunch.
        /// Must not be treated as "nothing to recover".
        case failed
    }

    /// Recovers an `HKWorkoutSession` left active by the previous app run and finalizes it
    /// immediately through the normal `end()` flow (endCollection → finishWorkout →
    /// session.end) — the workout is saved without any user interaction. Returns a
    /// `StuckSession` snapshot for logging (delivered to exactly one caller), or `nil`
    /// when there was nothing to recover.
    func recoverAndFinalizeStuckSession() async -> StuckSession? {
        let task = recoveryLock.withLock {
            if let recoveryTask { return recoveryTask }
            let task = Task { [self] () -> RecoveryResult in
                guard session == nil else {
                    // A live workout owns session/builder — recovering now would overwrite
                    // them mid-workout. Leave the stuck session for the next trigger/launch.
                    Logger.watchSession.notice("[Recovery] skipped — a live session is active")
                    return RecoveryResult(snapshot: nil, retryable: true)
                }
                switch await recoverActiveSession() {
                case .recovered(let stuck):
                    await WorkoutFileLogger.shared.log("[Recovery] auto-finalizing stuck session")
                    await end()
                    return RecoveryResult(snapshot: stuck, retryable: false)
                case .nothingToRecover:
                    return RecoveryResult(snapshot: nil, retryable: false)
                case .failed:
                    return RecoveryResult(snapshot: nil, retryable: true)
                }
            }
            recoveryTask = task
            return task
        }
        let result = await task.value
        return recoveryLock.withLock {
            if result.retryable, recoveryTask == task {
                recoveryTask = nil
            }
            guard let snapshot = result.snapshot, !recoverySnapshotDelivered else { return nil }
            recoverySnapshotDelivered = true
            return snapshot
        }
    }

    /// Attempts to recover an `HKWorkoutSession` left active by the previous app run.
    ///
    /// Wraps `HKHealthStore.recoverActiveWorkoutSession()` (watchOS 9+). On success,
    /// reattaches the session and its associated builder to this manager — wiring delegates,
    /// resetting the `workoutFinished` guard so a subsequent `end()` will save the workout.
    private func recoverActiveSession() async -> RecoveryOutcome {
        await WorkoutFileLogger.shared.log("[Recovery] checking HK Store for stuck session...")
        do {
            guard let recovered = try await healthStore.recoverActiveWorkoutSession() else {
                Logger.watchSession.debug("recoverActiveWorkoutSession() — no stuck session")
                await WorkoutFileLogger.shared.log("[Recovery] no stuck session in HK Store — nothing to recover")
                return .nothingToRecover
            }
            let activityTypeRaw = recovered.workoutConfiguration.activityType.rawValue
            let startDate = recovered.startDate ?? .now
            Logger.watchSession.notice("[Recovery] stuck session detected — activityType=\(activityTypeRaw), startDate=\(startDate)")
            await WorkoutFileLogger.shared.log("[Recovery] stuck session detected, activityType=\(activityTypeRaw), startDate=\(startDate)")

            session = recovered
            builder = recovered.associatedWorkoutBuilder()
            recovered.delegate = self
            builder?.delegate = self
            workoutFinished = false

            return .recovered(StuckSession(activityTypeRaw: activityTypeRaw, startDate: startDate))
        } catch {
            Logger.watchSession.error("recoverActiveWorkoutSession() failed: \(error.localizedDescription)")
            await WorkoutFileLogger.shared.log("[Recovery] FAILED — \(error.localizedDescription)")
            return .failed
        }
    }
}

// MARK: - HKWorkoutSessionDelegate

extension WatchWorkoutSessionManager: HKWorkoutSessionDelegate {

    func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        // Identity guard (mirror of IOS-00098-B on the iPhone side): a late callback
        // from a previous, already-replaced session must not touch current state —
        // in particular a stale `.ended` would fire the safety-net against the NEW
        // builder and flip `workoutFinished`, silently skipping the next real save.
        guard workoutSession === session else {
            Logger.watchSession.notice("ignoring didChangeTo \(toState.description) from stale session")
            return
        }

        Logger.watchSession.info("delegate: sessionState \(fromState.description) → \(toState.description)")
        Task {
            await WorkoutFileLogger.shared.log("[Delegate] sessionState \(fromState.description) → \(toState.description)")
        }

        // .ended included: a recovered zombie session can skip .stopped entirely —
        // without resuming here the recovery end flow would hang on the continuation.
        if toState == .stopped || toState == .ended {
            resumeSessionStopped()
        }

        // Forward pause/resume to HRMirrorFeature so its UI stays in sync
        // when iPhone initiates pause via the mirrored session.
        if toState == .paused || toState == .running {
            stateContinuation?.yield(toState)
            // Pause must be a real pause for the ride pipeline: no route points,
            // no rolling-window time. Covers pauses from either device.
            routeRecorder?.setPaused(toState == .paused)
            rideLock.withLock { rideMetrics.setPaused(toState == .paused, at: date) }
        }

        if toState == .ended, !workoutFinished, let builder {
            // Safety net: iPhone may have ended the mirrored session via HealthKit before
            // endSession() was called on Watch. Save the workout here to avoid data loss.
            workoutFinished = true
            Logger.watchSession.notice("session ended externally — saving via safety-net (workoutFinished was false)")
            Task {
                do {
                    try await builder.endCollection(at: date)
                    let workout = try await builder.finishWorkout()
                    self.lastSavedWorkoutUUID = workout?.uuid
                    self.lastSavedWorkoutSummary = self.makeSummary(from: workout)
                    if let workout {
                        await self.routeRecorder?.finishRoute(for: workout)
                    }
                    // end() may never run on this path (session ended externally) —
                    // stop GPS here too; recorder guards make a later double stop safe.
                    self.locationsTask?.cancel()
                    self.routeRecorder?.stop()
                    Logger.watchSession.info("safety-net: workout saved (uuid=\(workout?.uuid.uuidString ?? "nil"))")
                    await WorkoutFileLogger.shared.log("WATCH WORKOUT SAVED (safety-net, uuid=\(workout?.uuid.uuidString ?? "nil"))")
                } catch {
                    Logger.watchSession.error("safety-net finishWorkout failed: \(error)")
                }
            }
        }
    }

    /// Decodes incoming `Data` blobs as `WatchWorkoutEvent` and forwards them to
    /// `remoteEventStream`. Replaces the WatchConnectivity path for events that need
    /// reliable delivery even when `WCSession.isReachable == false` (e.g. `.workoutEnded`
    /// — the pre-existing iPhone-initiated End bug).
    func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didReceiveDataFromRemoteWorkoutSession data: [Data]
    ) {
        for payload in data {
            guard let event = try? JSONDecoder().decode(WatchWorkoutEvent.self, from: payload) else {
                Logger.watchSession.debug("didReceiveDataFromRemoteWorkoutSession — payload not a WatchWorkoutEvent (\(payload.count) bytes), ignored")
                continue
            }
            Logger.watchSession.info("didReceiveDataFromRemoteWorkoutSession — decoded \(String(describing: event))")
            // Rounds-timer segment relayed from the iPhone timer: this manager
            // owns the builder, so it persists the HKWorkoutEvent(.segment)
            // itself — features never see this event.
            if case let .roundSegmentCompleted(segment) = event {
                recordRoundSegment(segment)
                continue
            }
            remoteEventContinuation?.yield(event)
        }
    }

    /// Writes a relayed rounds-timer segment onto the live builder.
    /// Fire-and-forget — a failure (e.g. collection already ended) only logs;
    /// round marking must never disturb the workout itself.
    private func recordRoundSegment(_ segment: RoundSegment) {
        guard let builder, !workoutFinished else {
            Logger.watchSession.notice("recordRoundSegment — no live builder (round \(segment.roundIndex)), dropped")
            return
        }
        Task {
            do {
                try await builder.addWorkoutEvents([segment.workoutEvent])
                Logger.watchSession.info("recordRoundSegment — round \(segment.roundIndex) \(segment.kind.rawValue) persisted")
            } catch {
                Logger.watchSession.error("recordRoundSegment failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {
        let nsError = error as NSError
        let domain = nsError.domain
        let code = nsError.code
        let state = workoutSession.state.description
        let description = error.localizedDescription
        Logger.watchSession.error("session failed — domain=\(domain), code=\(code), state=\(state), description=\(description)")
        Task {
            await WorkoutFileLogger.shared.log("[Delegate] FAILED — domain=\(domain), code=\(code), state=\(state), error=\(description)")
        }
        // A failed session will never reach .stopped — unblock a pending end flow.
        if workoutSession === session {
            resumeSessionStopped()
        }
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate

extension WatchWorkoutSessionManager: HKLiveWorkoutBuilderDelegate {

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        for type in collectedTypes {
            guard
                let quantityType = type as? HKQuantityType,
                let stats = workoutBuilder.statistics(for: quantityType)
            else { continue }

            switch quantityType {
            case HKQuantityType(.heartRate):
                let bpmUnit = HKUnit.count().unitDivided(by: .minute())
                if let bpm = stats.mostRecentQuantity()?.doubleValue(for: bpmUnit) {
                    hrContinuation?.yield(bpm)
                }

            case HKQuantityType(.distanceCycling), HKQuantityType(.distanceWalkingRunning):
                if let total = stats.sumQuantity()?.doubleValue(for: .meter()) {
                    let sampleDate = stats.mostRecentQuantityDateInterval()?.end ?? Date()
                    rideLock.withLock { rideMetrics.recordDistance(total: total, at: sampleDate) }
                }

            default:
                break
            }
        }
    }
}
