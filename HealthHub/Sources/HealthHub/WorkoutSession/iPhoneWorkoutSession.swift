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

    // MARK: - Ride tracking (distance activities)

    /// GPS pipeline for outdoor, distance-based activities — live speed samples
    /// plus silent route capture (map shows up in the post-workout summary only).
    private var routeRecorder: WorkoutRouteRecorder?

    /// Turns GPS speed + builder distance into the ride fields of
    /// `WorkoutMetrics`. Guarded by `metricsLock` (GPS task and HK callbacks
    /// mutate it concurrently).
    private var rideMetrics = RideMetricsAccumulator()

    /// Consumes `routeRecorder.locations` into `rideMetrics` and broadcasts.
    private var locationsTask: Task<Void, Never>?

    // MARK: - Strap HR fallback

    /// HealthKit can stall mid-workout while the strap keeps sending (zombie
    /// connection — builder repeats a frozen value for minutes, no disconnect
    /// callback, no recovery API). When the builder's HR sample date stops
    /// moving but the app's own GATT subscription still delivers readings, the
    /// broadcast substitutes the live strap value — every `metrics` subscriber
    /// (live UI, effort points, GymRoom payload) recovers transparently.

    /// No fresh builder HR sample for longer than this = HealthKit is stalled.
    /// Mirrors `LiveSessionFeature.sensorStaleThreshold` so the fallback engages
    /// in step with the staleness banner.
    private static let hkHeartRateStaleThreshold: TimeInterval = 35

    /// A strap reading older than this is itself stale — the strap dropped too,
    /// so there is nothing truthful to substitute.
    private static let strapReadingFreshWindow: TimeInterval = 10

    /// Latest reading from the strap's GATT notifications. `metricsLock`-guarded.
    private var latestStrapReading: StrapHRReading?

    /// Whether the last broadcast substituted strap data — drives transition
    /// logs only (ACTIVE/OFF once, not per sample). `metricsLock`-guarded.
    private var isStrapFallbackActive = false

    /// Set at `start(at:)` — lets the staleness check treat "no HK sample yet"
    /// as stale only after the threshold, not in the warmup seconds.
    private var collectionStartDate: Date?

    /// Consumes the strap GATT stream into `latestStrapReading`.
    private var strapReadingsTask: Task<Void, Never>?

    /// Emits substituted metrics while HealthKit is FULLY silent (not even
    /// frozen repeats) — without it the fallback only rides on HK callbacks.
    private var fallbackTickerTask: Task<Void, Never>?


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
        builder.dataSource = Self.makeDataSource(
            healthStore: healthStore,
            configuration: configuration
        )

        // Warmup HK + BLE sensor pairing. The 3 s countdown in UI uses this gap.
        session.prepare()

        self.session = session
        self.builder = builder
        endClaimLock.withLock { hasEnded = false }
        startRideTrackingIfNeeded(for: configuration)

        Logger.iPhoneWorkoutSession.info("prepare() — session created, builder attached, dataSource bound")
    }

    /// Spins up the ride pipeline for distance-based activities. The accumulator
    /// resets for every distance workout (indoor treadmill included — pace comes
    /// from HealthKit distance deltas there); the GPS recorder starts only for
    /// `.outdoor` sessions — indoor workouts must not capture a route.
    /// Shared by `prepare()` and `reattach(to:)` (rule R7: fresh state per entry
    /// point; a route interrupted by a crash restarts from the recovery point).
    private func startRideTrackingIfNeeded(for configuration: HKWorkoutConfiguration) {
        guard configuration.activityType.collectsDistance else { return }
        metricsLock.withLock { rideMetrics = RideMetricsAccumulator() }
        guard configuration.locationType == .outdoor else {
            Logger.iPhoneWorkoutSession.info("ride tracking without GPS — indoor session, metrics from HealthKit distance only")
            return
        }

        let recorder = WorkoutRouteRecorder(healthStore: healthStore)
        routeRecorder = recorder
        recorder.start()

        locationsTask?.cancel()
        locationsTask = Task { [weak self] in
            for await location in recorder.locations {
                guard let self else { return }
                let merged = self.metricsLock.withLock {
                    self.rideMetrics.recordLocationSpeed(location.speed, at: location.timestamp)
                    self.currentMetrics = self.rideMetrics.apply(
                        to: self.currentMetrics,
                        elapsedTime: self.builder?.elapsedTime ?? 0,
                        at: Date()
                    )
                    return self.currentMetrics
                }
                self.broadcastMetrics(self.strapFallback(applyTo: merged).metrics)
            }
        }
        Logger.iPhoneWorkoutSession.info("ride tracking started — GPS + route capture active")
    }

    public func start(at date: Date) async throws {
        guard let session, let builder else {
            Logger.iPhoneWorkoutSession.error("start(at:) called before prepare()")
            throw iPhoneWorkoutSessionError.notPrepared
        }
        session.startActivity(with: date)
        try await builder.beginCollection(at: date)
        metricsLock.withLock { collectionStartDate = date }
        startFallbackTicker()
        Logger.iPhoneWorkoutSession.info("start(at:) — activity started at \(date)")
    }

    /// Subscribes the strap GATT stream that feeds the HR fallback. Called by
    /// the session owner right after `prepare()` — before any metrics flow.
    public func attachStrapFallback(_ readings: AsyncStream<StrapHRReading>) {
        strapReadingsTask?.cancel()
        strapReadingsTask = Task { [weak self] in
            for await reading in readings {
                guard let self else { return }
                self.metricsLock.withLock { self.latestStrapReading = reading }
            }
        }
    }

    /// Covers the worst stall flavour: HealthKit stops calling `didCollectDataOf`
    /// entirely, so there is no callback to piggyback the substitution on.
    private func startFallbackTicker() {
        fallbackTickerTask?.cancel()
        fallbackTickerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard let self, self.session?.state == .running else { continue }
                let snapshot = self.metricsLock.withLock { self.currentMetrics }
                let (substituted, isActive) = self.strapFallback(applyTo: snapshot)
                if isActive {
                    self.broadcastMetrics(substituted)
                }
            }
        }
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
            strapReadingsTask?.cancel()
            fallbackTickerTask?.cancel()
            locationsTask?.cancel()
            routeRecorder?.stop()
            session.end()
            finishWorkoutStream()
            Logger.iPhoneWorkoutSession.info("end() — session.end() invoked, workout stream finished")
        }

        let endDate = Date()
        do {
            // Timing markers: on 29.07 endWorkout() hung for 91 s somewhere in
            // these two HealthKit calls — the marker pair localizes which one.
            await WorkoutFileLogger.shared.log("[End] endCollection…")
            try await builder.endCollection(at: endDate)
            await WorkoutFileLogger.shared.log("[End] endCollection done → finishWorkout…")
            let finalWorkout = try await builder.finishWorkout()
            await WorkoutFileLogger.shared.log("[End] finishWorkout done")
            if let workout = finalWorkout {
                // Route attaches to the saved workout as a separate HK object —
                // history's map view picks it up with no further wiring.
                await routeRecorder?.finishRoute(for: workout)
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
        builder.dataSource = Self.makeDataSource(
            healthStore: healthStore,
            configuration: recoveredSession.workoutConfiguration
        )

        self.session = recoveredSession
        self.builder = builder
        // Crash recovery is the second session entry point — the end claim must
        // reset here just like in `prepare()` (rule R7), or `end()` on the
        // recovered session could silently no-op.
        endClaimLock.withLock { hasEnded = false }
        startRideTrackingIfNeeded(for: recoveredSession.workoutConfiguration)

        Logger.iPhoneWorkoutSession.info("reattach — session+builder restored (state=\(recoveredSession.state.rawValue))")
    }

    /// Builds the live data source for a session, gating distance collection.
    ///
    /// Indoor/stationary activities (boxing, strength, functional, cross) must not
    /// record distance — arm swings and steps between stations otherwise become the
    /// workout's headline metric in Apple Fitness. Shared by `prepare()` and
    /// `reattach(to:)` so crash recovery applies the same gate.
    private static func makeDataSource(
        healthStore: HKHealthStore,
        configuration: HKWorkoutConfiguration
    ) -> HKLiveWorkoutDataSource {
        let dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore,
            workoutConfiguration: configuration
        )
        if !configuration.activityType.collectsDistance {
            dataSource.disableCollection(for: HKQuantityType(.distanceWalkingRunning))
            dataSource.disableCollection(for: HKQuantityType(.distanceCycling))
        }
        return dataSource
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

    /// Substitutes the strap's own GATT reading for the heart-rate fields when
    /// HealthKit stalled but the strap is alive. Reads RAW builder metrics (the
    /// accumulator keeps the frozen HK sample date), so the staleness check has
    /// no feedback loop with its own substituted output.
    private func strapFallback(applyTo metrics: WorkoutMetrics) -> (metrics: WorkoutMetrics, isActive: Bool) {
        let now = Date()

        metricsLock.lock()
        let reading = latestStrapReading
        let startDate = collectionStartDate
        let wasActive = isStrapFallbackActive
        metricsLock.unlock()

        let hkIsStale: Bool
        if let hkDate = metrics.heartRateSampleDate {
            hkIsStale = now.timeIntervalSince(hkDate) > Self.hkHeartRateStaleThreshold
        } else if let startDate {
            // No HK sample at all — stale only past the threshold, so the
            // warmup seconds right after start don't trigger the fallback.
            hkIsStale = now.timeIntervalSince(startDate) > Self.hkHeartRateStaleThreshold
        } else {
            hkIsStale = false
        }

        let strapIsFresh = reading.map { now.timeIntervalSince($0.date) < Self.strapReadingFreshWindow } ?? false
        let isActive = hkIsStale && strapIsFresh

        metricsLock.lock()
        isStrapFallbackActive = isActive
        metricsLock.unlock()

        if isActive != wasActive {
            Logger.iPhoneWorkoutSession.notice("HR fallback \(isActive ? "ACTIVE" : "OFF")")
            Task {
                await WorkoutFileLogger.shared.log(
                    isActive
                        ? "[Connection] HR fallback ACTIVE — substituting strap GATT readings (HK stalled)"
                        : "[Connection] HR fallback OFF — HealthKit samples resumed"
                )
            }
        }

        guard isActive, let reading else { return (metrics, false) }
        var substituted = metrics
        substituted.heartRate = Double(reading.bpm)
        substituted.heartRateSampleDate = reading.date
        return (substituted, true)
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
        // Pause must be a real pause for the ride pipeline: no route points, no
        // rolling-window time. Hooked on session state (not the pause() call) so
        // pauses from Live Activity / App Intents are covered too.
        if toState == .paused || toState == .running {
            routeRecorder?.setPaused(toState == .paused)
            metricsLock.withLock { rideMetrics.setPaused(toState == .paused, at: date) }
        }
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

            case HKQuantityType(.distanceCycling), HKQuantityType(.distanceWalkingRunning):
                if let total = statistics?.sumQuantity()?.doubleValue(for: .meter()) {
                    let sampleDate = statistics?.mostRecentQuantityDateInterval()?.end ?? Date()
                    metricsLock.withLock { rideMetrics.recordDistance(total: total, at: sampleDate) }
                }

            default:
                continue
            }
        }

        if configuration.activityType.collectsDistance {
            working = metricsLock.withLock {
                rideMetrics.apply(to: working, elapsedTime: workoutBuilder.elapsedTime, at: Date())
            }
        }

        metricsLock.lock()
        currentMetrics = working
        metricsLock.unlock()

        // The accumulator above stays RAW; only the broadcast gets the
        // fallback-substituted view. This also rewrites the frozen repeats HK
        // keeps emitting during a stall, so consumers never see them.
        broadcastMetrics(strapFallback(applyTo: working).metrics)
    }
}

// MARK: - Errors

public enum iPhoneWorkoutSessionError: Error, Sendable {
    case notPrepared
}
