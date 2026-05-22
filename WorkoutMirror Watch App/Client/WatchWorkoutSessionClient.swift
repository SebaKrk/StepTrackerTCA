//
//  WatchWorkoutSessionClient.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Sciuba on 05/04/2026.
//

import ComposableArchitecture
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
    /// returns an `AsyncStream<Double>` of live BPM readings.
    var startSession: @Sendable (_ activityType: HKWorkoutActivityType) async -> AsyncStream<Double>

    /// Ends the active session: stops collection, discards the builder (no HKWorkout saved), ends the session.
    var endSession: @Sendable () async -> Void

    /// Sends a `WorkoutMetrics` snapshot to the paired iPhone via HealthKit's native mirroring channel
    /// (`sendToRemoteWorkoutSession`). Only used in Watch-primary mode — replaces WatchConnectivity
    /// `.hrReading` events for HR transfer.
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
    /// (e.g. iPhone died mid-workout, Watch app force-quit). Wraps
    /// `HKHealthStore.recoverActiveWorkoutSession()` (watchOS 9+).
    ///
    /// When a stuck session is found, the manager attaches to it — reconnects delegates and
    /// recovers the associated builder — so subsequent `recoverAndEnd` / `recoverAndDiscard`
    /// operates on the live session. Returns `nil` when no stuck session exists; the normal
    /// start flow is then unaffected.
    var checkForStuckSession: @Sendable () async -> StuckSession?

    /// Finalizes a previously recovered stuck session: `endCollection` → `finishWorkout` → `session.end`.
    /// Delegates to the same flow as `endSession()`. Used when the user taps "Zakończ teraz".
    var recoverAndEnd: @Sendable () async -> Void

    /// Discards a previously recovered stuck session: `builder.discardWorkout` → `session.end`.
    /// No `HKWorkout` is saved. Used when the user taps "Odrzuć".
    var recoverAndDiscard: @Sendable () async -> Void
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
            startSession: { activityType in
                await manager.start(activityType: activityType)
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
            checkForStuckSession: {
                await manager.recoverActiveSession()
            },
            recoverAndEnd: {
                await WorkoutFileLogger.shared.log("[Recovery] recoverAndEnd — calling manager.end()")
                await manager.end()
                await WorkoutFileLogger.shared.log("[Recovery] recoverAndEnd — manager.end() returned")
            },
            recoverAndDiscard: {
                await manager.discardRecoveredSession()
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

    /// Resolved by `HKWorkoutSessionDelegate` when session transitions to `.stopped`.
    /// Used to bridge the async gap between `stopActivity()` and the delegate callback.
    private var sessionStoppedContinuation: CheckedContinuation<Void, Never>?

    /// Guards against calling `finishWorkout()` twice — once from the explicit `end()` call
    /// and once from the `.ended` safety-net handler in the session delegate.
    private var workoutFinished = false

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

    func start(activityType: HKWorkoutActivityType) async -> AsyncStream<Double> {
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

        let config = HKWorkoutConfiguration()
        config.activityType = activityType
        config.locationType = .unknown

        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            builder = session?.associatedWorkoutBuilder()
            session?.delegate = self
            builder?.delegate = self
            builder?.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: config
            )

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
        } catch {
            Logger.watchSession.error("start() failed to create HKWorkoutSession: \(error)")
            continuation.finish()
        }

        return stream
    }

    func end() async {
        defer {
            hrContinuation?.finish()
            hrContinuation = nil
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
                _ = try await builder.finishWorkout()
                Logger.watchSession.info("end() ✓ workout saved to HealthKit")
                await WorkoutFileLogger.shared.log("WATCH WORKOUT SAVED")
            } catch {
                Logger.watchSession.error("end() finishWorkout failed: \(error)")
                await WorkoutFileLogger.shared.log("[End] finishWorkout FAILED: \(error.localizedDescription)")
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

        let metrics = WorkoutMetrics(averageHeartRate: avgHR, heartRate: bpm, activeEnergy: energy)
        guard let data = try? JSONEncoder().encode(metrics) else {
            Logger.watchSession.error("sendHRToRemote — failed to encode WorkoutMetrics")
            return
        }
        do {
            try await session.sendToRemoteWorkoutSession(data: data)
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

    /// Calls `session.stopActivity()` and suspends until the delegate confirms `.stopped`.
    ///
    /// If the session is already stopped or ended (e.g. crash recovery), skips immediately
    /// to avoid hanging on a continuation that will never be resumed.
    private func stopActivityAndWait(_ session: HKWorkoutSession) async {
        guard session.state == .running || session.state == .paused else {
            Logger.watchSession.info("stopActivityAndWait — skipped (state=\(session.state.rawValue) not running/paused)")
            return
        }
        Logger.watchSession.info("stopActivityAndWait — calling stopActivity(), awaiting delegate .stopped")
        await withCheckedContinuation { continuation in
            sessionStoppedContinuation = continuation
            session.stopActivity(with: .now)
        }
        Logger.watchSession.info("stopActivityAndWait — .stopped confirmed by delegate")
    }

    /// Attempts to recover an `HKWorkoutSession` left active by the previous app run.
    ///
    /// Wraps `HKHealthStore.recoverActiveWorkoutSession()` (watchOS 9+). On success,
    /// reattaches the session and its associated builder to this manager — wiring delegates,
    /// resetting the `workoutFinished` guard so a subsequent `end()` will save the workout —
    /// and returns a `StuckSession` snapshot for the UI. Returns `nil` if no stuck session
    /// exists or recovery fails (logged, non-fatal).
    func recoverActiveSession() async -> StuckSession? {
        await WorkoutFileLogger.shared.log("[Recovery] checking HK Store for stuck session...")
        do {
            guard let recovered = try await healthStore.recoverActiveWorkoutSession() else {
                Logger.watchSession.debug("recoverActiveWorkoutSession() — no stuck session")
                await WorkoutFileLogger.shared.log("[Recovery] no stuck session in HK Store — nothing to recover")
                return nil
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

            return StuckSession(activityTypeRaw: activityTypeRaw, startDate: startDate)
        } catch {
            Logger.watchSession.error("recoverActiveWorkoutSession() failed: \(error.localizedDescription)")
            await WorkoutFileLogger.shared.log("[Recovery] FAILED — \(error.localizedDescription)")
            return nil
        }
    }

    /// Discards a previously recovered stuck session without saving an `HKWorkout`.
    /// Used when the user chooses "Odrzuć" in the recovery alert.
    func discardRecoveredSession() async {
        defer {
            session = nil
            builder = nil
            workoutFinished = false
        }
        Logger.watchSession.info("discardRecoveredSession() — discarding builder + ending session")
        builder?.discardWorkout()
        session?.end()
        await WorkoutFileLogger.shared.log("[Recovery] discarded — no HKWorkout saved")
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
        Logger.watchSession.info("delegate: sessionState \(fromState.description) → \(toState.description)")
        Task {
            await WorkoutFileLogger.shared.log("[Delegate] sessionState \(fromState.description) → \(toState.description)")
        }

        if toState == .stopped {
            sessionStoppedContinuation?.resume()
            sessionStoppedContinuation = nil
        }

        // Forward pause/resume to HRMirrorFeature so its UI stays in sync
        // when iPhone initiates pause via the mirrored session.
        if toState == .paused || toState == .running {
            stateContinuation?.yield(toState)
        }

        if toState == .ended, !workoutFinished, let builder {
            // Safety net: iPhone may have ended the mirrored session via HealthKit before
            // endSession() was called on Watch. Save the workout here to avoid data loss.
            workoutFinished = true
            Logger.watchSession.notice("session ended externally — saving via safety-net (workoutFinished was false)")
            Task {
                do {
                    try await builder.endCollection(at: date)
                    _ = try await builder.finishWorkout()
                    Logger.watchSession.info("safety-net: workout saved to HealthKit")
                    await WorkoutFileLogger.shared.log("WATCH WORKOUT SAVED (safety-net)")
                } catch {
                    Logger.watchSession.error("safety-net finishWorkout failed: \(error)")
                }
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
                quantityType == HKQuantityType(.heartRate),
                let stats = workoutBuilder.statistics(for: quantityType)
            else { continue }

            let bpmUnit = HKUnit.count().unitDivided(by: .minute())
            if let bpm = stats.mostRecentQuantity()?.doubleValue(for: bpmUnit) {
                hrContinuation?.yield(bpm)
            }
        }
    }
}
