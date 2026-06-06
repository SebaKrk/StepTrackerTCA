//
//  SessionClient.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 28/08/2025.
//

import ComposableArchitecture
import Foundation
import HealthKit
import HealthHub
import OSLog
import SharedModels

// MARK: - WorkoutMode

/// Determines which device owns the active `HKWorkoutSession`.
///
/// - `watchPrimary`: Apple Watch runs the primary session and mirrors it to iPhone.
///   iPhone controls the session via the mirrored `HKWorkoutSession`.
/// - `iPhoneStandalone`: iPhone runs its own primary session (iOS 26).
///   Used when Watch is unavailable or not paired.
enum WorkoutMode: Equatable, Sendable {
    case watchPrimary
    case iPhoneStandalone
}

// MARK: - SessionClient

struct SessionClient {
    var selectedWorkout: @Sendable (HKWorkoutActivityType?) async throws -> Void
    var workoutMetricsStream: @Sendable () async -> AsyncStream<WorkoutMetrics>
    var workoutSessionStateStream: @Sendable () async -> AsyncStream<HKWorkoutSessionState>
    var elapsedTimeAt: (_ date: Date) -> TimeInterval
    var togglePause: @Sendable () async -> Void
    var getWorkoutSummary: @Sendable () async -> WorkoutSummary
    var endWorkout: @Sendable () async -> Void
    /// Adds a Watch HR sample to iPhone's HKLiveWorkoutBuilder so that
    /// the saved HKWorkout contains heart-rate data collected by Watch sensors.
    /// Used in iPhone-standalone mode only; Watch-primary sends HR via HealthKit mirroring.
    var addHeartRateSample: @Sendable (Double, Date) async -> Void

    /// Launches the Watch app. In Watch-primary mode Watch then starts its own
    /// HKWorkoutSession, calls startMirroringToCompanionDevice(), and iPhone
    /// receives the mirrored session via workoutSessionMirroringStartHandler.
    var startWatchWorkout: @Sendable (HKWorkoutActivityType) async throws -> Void

    /// Deletes the given workout from HealthKit. Only works for workouts created
    /// by this app. Used when the user discards a just-finished workout.
    var deleteWorkout: @Sendable (HKWorkout) async throws -> Void

    /// Resets `metrics.heartRate` to 0 inside `DefaultWorkoutManager` so that
    /// subsequent HealthKit energy updates do not re-broadcast a stale HR value.
    /// Used in iPhone-standalone mode only.
    var resetWatchHeartRate: @Sendable () -> Void

    /// Switches internal routing between Watch-primary and iPhone-standalone mode.
    /// Must be called in `viewDidAppear` before the session begins.
    var setWorkoutMode: @Sendable (WorkoutMode) async -> Void

    /// Increments the internal elapsed-time counter by 1 second and returns the new value.
    ///
    /// Called from `SessionFeature.watchTickEffect` (which fires every second).
    /// In Watch-primary mode this is the sole source of truth for elapsed time, since
    /// the mirrored `HKWorkoutSession` on iPhone has no active `HKLiveWorkoutBuilder`.
    var incrementElapsed: @Sendable () -> TimeInterval

    /// Resets the internal elapsed-time counter to 0.
    /// Called at the moment the workout transitions from countdown to active session.
    var resetElapsed: @Sendable () -> Void

    /// Resets the interpolation baseline (`lastTickDate`) to now without changing the counter.
    ///
    /// Must be called on workout resume so sub-second interpolation does not include
    /// the pause duration. Without this, `elapsedAt(date)` overshoots because
    /// `lastTickDate` is still the pre-pause tick timestamp.
    var markResumeElapsed: @Sendable () -> Void

    /// Starts the active `HKWorkoutSession` on iPhone.
    ///
    /// In iPhone-standalone mode, calls `workoutManager.startWorkout()` to begin
    /// HealthKit data collection after the countdown finishes.
    /// In Watch-primary mode, this is a no-op — Watch owns the session.
    var startWorkout: @Sendable () async -> Void

    /// One-shot signal stream — emits when iPhone receives the mirrored `HKWorkoutSession`
    /// from Apple Watch in `workoutSessionMirroringStartHandler`.
    ///
    /// Used by `SessionFeature` in Watch-primary mode to transition from
    /// `.waitingForWatch` UI state → `.countdown` (Apple Fitness-style startup flow).
    /// Each subscription receives a fresh stream; previous subscriber's continuation
    /// is finished — semantics match `workoutSessionStateStream`.
    var mirroredSessionStartedStream: @Sendable () async -> AsyncStream<Void>

    /// Sends a lifecycle event to Watch through the HealthKit mirroring channel
    /// (`sendToRemoteWorkoutSession`). Reliable even when WatchConnectivity is unreachable.
    ///
    /// Used for `.workoutEnded` in Watch-primary mode — fixes the pre-existing bug where
    /// iPhone-initiated End would be dropped if `WCSession.isReachable == false`. The HK
    /// channel does not require reachability — it propagates through the OS-managed mirror.
    var sendLifecycleEventToWatch: @Sendable (WatchWorkoutEvent) async -> Void

    /// Rebuilds `HKLiveWorkoutBuilder` + `HKLiveWorkoutDataSource` for a `.primary` session
    /// recovered after iPhone app crash via `HKHealthStore.recoverActiveWorkoutSession()`.
    ///
    /// Called from `AppDelegate` after `trainingManager.recover(session:)` — only for sessions
    /// of type `.primary` (iPhone-standalone). `.mirroredFromRemoteDevice` recovery is a no-op
    /// here because Watch owns the builder. Per WWDC25: HealthKit returns the running session
    /// but builder + dataSource references die with the crashed process.
    var recoverPrimarySession: @Sendable (HKWorkoutSession) async throws -> Void
}

// MARK: - Dependency Registration

extension DependencyValues {
    var sessionClient: SessionClient {
        get { self[SessionClientClientKey.self] }
        set { self[SessionClientClientKey.self] = newValue }
    }
}

private enum SessionClientClientKey: DependencyKey {
    static let liveValue: SessionClient = {

        // ⚠️ ════════════════════════════════════════════════════════════════════════
        // ⚠️  LEGACY — DO NOT USE IN NEW CODE
        // ⚠️ ════════════════════════════════════════════════════════════════════════
        //
        // `workoutManager` (DefaultWorkoutManager) is the LEGACY iOS<26 path —
        // Watch-as-HR-sensor model via WatchConnectivity.
        //
        // In iOS 26+ iPhone-standalone uses `iPhoneWorkoutSession` (created in
        // `WorkoutModeRouter.prepareIPhoneSession`). When this path is active,
        // `manager.builder`, `manager.getWorkout()` etc. are NIL — reading from
        // them in iOS 26+ flow produces silent failures (e.g. stopwatch stuck at 0,
        // `workout: nil` in summary polling).
        //
        // Existing `manager.*` calls below are kept as iOS<26 fallback only.
        // Each is marked `// LEGACY iOS<26`. NEW reads of metrics/state/workout
        // MUST go through `router` (which routes to iPhoneSession in iOS 26+).
        @Dependency(\.workoutManager) var manager
        @Dependency(\.trainingManager) var trainingManager
        @Dependency(\.healthStore) var healthStore
        @Dependency(\.authorizationManager) var authorizationManager

        // Actor that holds current mode and routes calls accordingly.
        // healthStore + authorizationManager are passed so the router can lazily create
        // an `iPhoneWorkoutSession` (iOS 26+) for the iPhone-standalone path.
        let router = WorkoutModeRouter(
            workoutManager: manager,
            trainingManager: trainingManager,
            healthStore: healthStore,
            authorizationManager: authorizationManager
        )

        // Synchronous mode holder — allows `elapsedTimeAt` and `getWorkoutSummary`
        // to route without actor async overhead. Mode is set once at session start
        // so race conditions are not a concern in practice.
        let modeHolder = ModeHolder()

        // Elapsed time counter for Watch-primary mode.
        let elapsedTracker = ElapsedTracker()

        return SessionClient(
            selectedWorkout: { type in
                // Per WWDC25 #322: exactly ONE HKWorkoutSession owns the iPhone side
                // per workout cycle. Previous code also called `manager.setSelectedWorkout`
                // which triggered `DefaultWorkoutManager.prepareWorkout()` → created a
                // parallel HKWorkoutSession → HK rejected with code=8 "Another session
                // is starting" → legacy session became zombie → cascade of bugs
                // (workout: nil in summary, missing metrics broadcasts, etc.).
                //
                // 3s countdown overlaps BLE strap warmup (CLAUDE.md R1: prepare() before start).
                if let type {
                    await router.prepareIPhoneSession(activityType: type)
                }
            },
            workoutMetricsStream: {
                await router.metricsStream()
            },
            workoutSessionStateStream: {
                await router.sessionStateStream()
            },
            elapsedTimeAt: { date in
                // Both modes use ElapsedTracker as single source of truth — driven by
                // watchTickEffect (1Hz) + TimelineView sub-second interpolation.
                //
                // Watch-primary: iPhone has no active HKLiveWorkoutBuilder (mirrored session).
                // iPhone-standalone (iOS 26+): real builder lives inside iPhoneWorkoutSession
                // (actor-isolated, sync access impossible). Legacy `manager.builder` was nil
                // in this path → UI stuck on 00:00. ElapsedTracker gives identical UX to
                // HKLiveWorkoutBuilder.elapsedTime(at:) — see comment on `ElapsedTracker`.
                return elapsedTracker.elapsedAt(date)
            },
            togglePause: {
                await router.togglePause()
            },
            getWorkoutSummary: {
                switch modeHolder.mode {
                case .watchPrimary:
                    // Step 1: trainingManager stored workout (set by handleWorkoutEndIOS
                    // if the mirrored session's .ended delegate fired).
                    if let workout = trainingManager.getWorkout() {
                        return WorkoutSummary(workout: workout,
                                             metrics: trainingManager.getWorkoutMetrics())
                    }

                    // Step 2: defense in depth — direct HK fetch when delegate path failed
                    // (e.g. iPhone backgrounded during Watch end, .ended never observed).
                    // Newest workout from the last hour wins.
                    let oneHourAgo = Date().addingTimeInterval(-3600)
                    let datePredicate = HKQuery.predicateForSamples(
                        withStart: oneHourAgo,
                        end: Date()
                    )
                    let descriptor = HKSampleQueryDescriptor(
                        predicates: [.workout(datePredicate)],
                        sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
                        limit: 1
                    )
                    do {
                        let samples = try await descriptor.result(for: healthStore)
                        if let workout = samples.first {
                            Logger.session.info("getWorkoutSummary — direct HK fetch found: \(workout.uuid.uuidString)")
                            return WorkoutSummary(workout: workout,
                                                 metrics: trainingManager.getWorkoutMetrics())
                        }
                    } catch {
                        Logger.session.error("getWorkoutSummary — direct HK fetch failed: \(error.localizedDescription)")
                    }

                    return WorkoutSummary(workout: nil,
                                         metrics: trainingManager.getWorkoutMetrics())
                case .iPhoneStandalone:
                    // iPhone-standalone (iOS 26+): read from WorkoutModeRouter cache,
                    // populated by background subscription to `iPhoneSession.workout` +
                    // `iPhoneSession.metrics` streams. Legacy `manager.getWorkout()` always
                    // returned nil here (DefaultWorkoutManager bypassed by fix #3).
                    return await router.getWorkoutSummary()
                }
            },
            endWorkout: {
                await router.endWorkout()
            },
            addHeartRateSample: { bpm, date in
                await manager.addHeartRateSample(bpm, at: date)
            },
            startWatchWorkout: { activityType in
                try await trainingManager.startWatchWorkout(workoutType: activityType)
            },
            deleteWorkout: { workout in
                // Re-fetch by UUID to avoid stale reference race (workout may have
                // been deleted elsewhere, or never synced to iPhone HK yet). If
                // absent in HK → treat as success (idempotent — intent fulfilled).
                //
                // Diagnostic timing logs — user reported 15s delete delays for mirrored
                // workouts (Watch-saved). HealthKit's internal sync may block on iCloud
                // ack. Use these logs to locate the bottleneck (fetch vs delete).
                let totalStart = ContinuousClock.now
                Logger.session.info("deleteWorkout ▶ start (uuid=\(workout.uuid.uuidString))")

                let predicate = HKQuery.predicateForObject(with: workout.uuid)
                let descriptor = HKSampleQueryDescriptor(
                    predicates: [.workout(predicate)],
                    sortDescriptors: [],
                    limit: 1
                )
                let fetchStart = ContinuousClock.now
                let samples = try await descriptor.result(for: healthStore)
                let fetchElapsed = ContinuousClock.now - fetchStart
                Logger.session.info("deleteWorkout ◷ re-fetch took \(fetchElapsed.components.seconds)s \(fetchElapsed.components.attoseconds / 1_000_000_000_000_000)ms (found=\(samples.count))")

                if let fresh = samples.first {
                    let deleteStart = ContinuousClock.now
                    try await healthStore.delete(fresh)
                    let deleteElapsed = ContinuousClock.now - deleteStart
                    Logger.session.info("deleteWorkout ◷ delete took \(deleteElapsed.components.seconds)s \(deleteElapsed.components.attoseconds / 1_000_000_000_000_000)ms")
                } else {
                    Logger.session.info("deleteWorkout: workout already absent in HK — idempotent success")
                }

                let totalElapsed = ContinuousClock.now - totalStart
                Logger.session.info("deleteWorkout ✓ total \(totalElapsed.components.seconds)s \(totalElapsed.components.attoseconds / 1_000_000_000_000_000)ms")
            },
            resetWatchHeartRate: {
                manager.resetWatchHeartRate()
            },
            setWorkoutMode: { mode in
                modeHolder.mode = mode
                await router.setMode(mode)
            },
            incrementElapsed: {
                elapsedTracker.increment()
            },
            resetElapsed: {
                elapsedTracker.reset()
            },
            markResumeElapsed: {
                elapsedTracker.markResume()
            },
            startWorkout: {
                await router.startWorkout()
            },
            mirroredSessionStartedStream: {
                trainingManager.mirroredSessionStartedStream
            },
            sendLifecycleEventToWatch: { event in
                guard let data = try? JSONEncoder().encode(event) else {
                    Logger.session.error("sendLifecycleEventToWatch — failed to encode \(String(describing: event))")
                    return
                }
                await trainingManager.sendDataToWatch(data)
            },
            recoverPrimarySession: { session in
                try await router.recoverPrimarySession(session)
            }
        )
    }()
}

// MARK: - ModeHolder

/// Tracks elapsed workout time for Watch-primary mode.
///
/// `elapsed` is the last full-second value set by `watchTickEffect` (every 1s).
/// `elapsedAt(_:)` interpolates sub-second precision using `lastTickDate`,
/// giving smooth display at 60 fps from the View's TimelineView — identical to
/// how `HKLiveWorkoutBuilder.elapsedTime(at:)` works in iPhone-standalone mode.
private final class ElapsedTracker: @unchecked Sendable {
    private var elapsed: TimeInterval = 0
    private var lastTickDate: Date = Date()

    /// Returns interpolated elapsed time at `date`.
    func elapsedAt(_ date: Date) -> TimeInterval {
        guard elapsed > 0 else { return 0 }
        // Clamp fraction to 1s so a paused/delayed tick doesn't overshoot.
        let fraction = min(date.timeIntervalSince(lastTickDate), 1.0)
        return elapsed + max(0, fraction)
    }

    /// Increments the counter by 1 second and records the tick timestamp.
    @discardableResult
    func increment() -> TimeInterval {
        elapsed += 1
        lastTickDate = Date()
        return elapsed
    }

    /// Called on workout resume so the interpolation doesn't include pause duration.
    func markResume() {
        lastTickDate = Date()
    }

    func reset() {
        elapsed = 0
        lastTickDate = Date()
    }
}

/// Simple reference-type container for synchronous mode access.
///
/// `WorkoutModeRouter` is an `actor` (async-only access), but `elapsedTimeAt` and
/// `getWorkoutSummary` closures must be synchronous. `ModeHolder` bridges this gap:
/// mode is written once during `viewDidAppear` (before any reads), so no locking needed.
private final class ModeHolder: @unchecked Sendable {
    var mode: WorkoutMode = .iPhoneStandalone
}

// MARK: - WorkoutModeRouter

/// Actor that routes session control calls to the correct manager
/// depending on whether Watch or iPhone owns the primary session.
///
/// **iPhone-standalone routing** is iOS-version-dependent:
/// - **iOS 26+**: native `iPhoneWorkoutSession` (HKWorkoutSession on iPhone + BLE HR sensor)
/// - **iOS < 26**: legacy `workoutManager` (Watch-as-HR-sensor via WatchConnectivity)
///
/// The dual path exists because `HKWorkoutSession.init(healthStore:configuration:)` on iPhone
/// is iOS 26+ only. On older systems iPhone cannot own a workout session natively.
private actor WorkoutModeRouter {

    private var mode: WorkoutMode = .iPhoneStandalone
    private let workoutManager: WorkoutManager
    private let trainingManager: TrainingManager
    private let healthStore: HKHealthStore
    private let authorizationManager: AuthorizationManager

    /// Active iPhone-standalone session (iOS 26+ only). Reference type `(any WorkoutSession)?`
    /// is universal across iOS versions — only the instantiation is gated by `#available`.
    private var iPhoneSession: (any WorkoutSession)?

    /// Cached `HKWorkout` from `iPhoneSession.workout` stream — single emit after `finishWorkout()`.
    /// `getWorkoutSummary()` exposes this synchronously to `SessionClient` consumers, replacing
    /// the broken legacy path (`manager.getWorkout()` always nil in iPhone-standalone).
    private var lastSavedWorkout: HKWorkout?

    /// Cached metrics from `iPhoneSession.metrics` multicast stream — updated each builder tick.
    /// Snapshot exposed via `getWorkoutSummary()` for the Summary screen.
    private var lastMetrics: WorkoutMetrics = WorkoutMetrics(averageHeartRate: 0, heartRate: 0, activeEnergy: 0)

    /// Tasks bridging async streams into actor-cached state. Started in `prepareIPhoneSession`
    /// / `recoverPrimarySession`, cancelled in `endWorkout` after the streams have drained.
    private var workoutCacheTask: Task<Void, Never>?
    private var metricsCacheTask: Task<Void, Never>?

    init(
        workoutManager: WorkoutManager,
        trainingManager: TrainingManager,
        healthStore: HKHealthStore,
        authorizationManager: AuthorizationManager
    ) {
        self.workoutManager = workoutManager
        self.trainingManager = trainingManager
        self.healthStore = healthStore
        self.authorizationManager = authorizationManager
    }

    func setMode(_ newMode: WorkoutMode) {
        mode = newMode
        Logger.session.info("WorkoutModeRouter mode → \(String(describing: newMode))")
    }

    /// Creates `iPhoneWorkoutSession`, requests HealthKit authorization, and calls `prepare()`.
    /// Called from `selectedWorkout` closure so the 3s countdown overlaps BLE strap warmup.
    func prepareIPhoneSession(activityType: HKWorkoutActivityType) async {
        do {
            _ = await authorizationManager.requestAuthorization()
            let configuration = HKWorkoutConfiguration()
            configuration.activityType = activityType
            configuration.locationType = .outdoor
            let new = iPhoneWorkoutSession(healthStore: healthStore, configuration: configuration)
            try await new.prepare()
            iPhoneSession = new
            startCachingStreams(from: new)
            Logger.session.info("prepareIPhoneSession — iPhoneWorkoutSession prepared (activityType: \(activityType.rawValue))")
        } catch {
            Logger.session.error("prepareIPhoneSession failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Recovery after app crash for `.primary` (iPhone-standalone) sessions.
    /// Creates a fresh `iPhoneWorkoutSession` and reattaches builder + dataSource to the
    /// recovered HealthKit session. Sets routing to `iPhoneStandalone` because `.primary`
    /// sessions can only originate from iPhone — Watch-primary sessions appear as
    /// `.mirroredFromRemoteDevice` on iPhone side and are handled by HealthKit mirroring.
    func recoverPrimarySession(_ recoveredSession: HKWorkoutSession) async throws {
        let recovered = iPhoneWorkoutSession(
            healthStore: healthStore,
            configuration: recoveredSession.workoutConfiguration
        )
        try await recovered.reattach(to: recoveredSession)
        self.iPhoneSession = recovered
        self.mode = .iPhoneStandalone
        startCachingStreams(from: recovered)
        Logger.session.info("recoverPrimarySession — iPhoneWorkoutSession reattached (state=\(recoveredSession.state.rawValue))")
    }

    // MARK: - Workout Summary Cache (iPhone-standalone)

    /// Subscribes to `iPhoneSession.workout` (single emit on end) and `iPhoneSession.metrics`
    /// (multicast tick stream), caching values into actor state for sync `getWorkoutSummary()` access.
    ///
    /// - `workout` task exits naturally when stream finishes (`iPhoneWorkoutSession.end()` guarantees
    ///   `finish()` even when `finalWorkout` is nil).
    /// - `metrics` task is cancelled in `endWorkout()` — stream itself never finishes.
    private func startCachingStreams(from session: any WorkoutSession) {
        workoutCacheTask?.cancel()
        metricsCacheTask?.cancel()

        workoutCacheTask = Task { [weak self] in
            for await workout in session.workout {
                await self?.cacheWorkout(workout)
            }
        }
        metricsCacheTask = Task { [weak self] in
            for await metrics in session.metrics {
                await self?.cacheMetrics(metrics)
            }
        }
    }

    private func stopCachingStreams() {
        workoutCacheTask?.cancel()
        metricsCacheTask?.cancel()
        workoutCacheTask = nil
        metricsCacheTask = nil
    }

    private func cacheWorkout(_ workout: HKWorkout) {
        self.lastSavedWorkout = workout
        Logger.session.info("WorkoutModeRouter — cached workout uuid=\(workout.uuid.uuidString)")
    }

    private func cacheMetrics(_ metrics: WorkoutMetrics) {
        self.lastMetrics = metrics
    }

    /// Synchronous(ish) snapshot for `SessionClient.getWorkoutSummary` in iPhone-standalone path.
    /// Workout is populated after `iPhoneSession.workout` stream emits (post `finishWorkout()`).
    /// Until then returns `(nil, lastMetrics)` — Summary feature handles nil via its polling logic.
    func getWorkoutSummary() -> WorkoutSummary {
        WorkoutSummary(workout: lastSavedWorkout, metrics: lastMetrics)
    }

    func togglePause() async {
        switch mode {
        case .watchPrimary:
            // Mirrored session pause propagates to Watch automatically via HealthKit.
            trainingManager.togglePause()
        case .iPhoneStandalone:
            // Pause/resume routing stays on legacy `workoutManager.togglePause()` even
            // though `iPhoneWorkoutSession` handles start/end. Routing through
            // `iPhoneSession.pause()` / `.resume()` would require tracking current session
            // state inside this actor — `AsyncStream.first` blocks because
            // `iPhoneWorkoutSession.state` does not emit a baseline on subscription.
            workoutManager.togglePause()
        }
    }

    func endWorkout() async {
        switch mode {
        case .watchPrimary:
            // Watch-primary: Watch owns the session and MUST call finishWorkout() before
            // session.end(). Calling session.end() on the mirrored session here would
            // propagate via HealthKit and end Watch's primary session BEFORE Watch saves
            // the workout — causing the workout to be lost.
            Logger.session.info("WorkoutModeRouter endWorkout() — Watch-primary: no-op (Watch owns end sequence)")
        case .iPhoneStandalone:
            if let iPhoneSession {
                do {
                    try await iPhoneSession.end()
                    Logger.session.info("endWorkout — iPhoneWorkoutSession.end() succeeded")
                } catch {
                    Logger.session.error("iPhoneWorkoutSession.end() failed: \(error.localizedDescription, privacy: .public)")
                }
                // Wait for workout-cache task to drain the final `HKWorkout` emit
                // from `iPhoneSession.workout` stream (or natural finish on nil/error).
                // Without this, `getWorkoutSummary()` might race and return nil.
                await workoutCacheTask?.value
                stopCachingStreams()
                self.iPhoneSession = nil
            } else {
                workoutManager.endWorkout()
            }
        }
    }

    func startWorkout() async {
        switch mode {
        case .watchPrimary:
            // Watch-primary: Watch already started the HKWorkoutSession.
            // iPhone has a mirrored session — no startWorkout() needed.
            Logger.session.info("WorkoutModeRouter startWorkout() — Watch-primary: no-op")
        case .iPhoneStandalone:
            if let iPhoneSession {
                do {
                    try await iPhoneSession.start(at: Date())
                    Logger.session.info("startWorkout — iPhoneWorkoutSession started")
                } catch {
                    Logger.session.error("iPhoneWorkoutSession.start failed: \(error.localizedDescription, privacy: .public)")
                }
            } else {
                await workoutManager.startWorkout()
            }
        }
    }

    func sessionStateStream() -> AsyncStream<HKWorkoutSessionState> {
        switch mode {
        case .watchPrimary:
            return trainingManager.workoutSessionStateStream
        case .iPhoneStandalone:
            if let iPhoneSession {
                return iPhoneSession.state
            } else {
                return workoutManager.workoutSessionStateStream
            }
        }
    }

    func metricsStream() -> AsyncStream<WorkoutMetrics> {
        switch mode {
        case .watchPrimary:
            // In Watch-primary, metrics come from Watch via sendToRemoteWorkoutSession
            // decoded in DefaultTrainingManager.didReceiveDataFromRemoteWorkoutSession.
            return trainingManager.workoutMetricsStream
        case .iPhoneStandalone:
            if let iPhoneSession {
                return iPhoneSession.metrics
            } else {
                return workoutManager.workoutMetricsStream
            }
        }
    }
}
