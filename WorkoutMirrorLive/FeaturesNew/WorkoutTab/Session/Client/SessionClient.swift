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
                manager.setSelectedWorkout(type)
                // iOS 26+ iPhone-standalone — prepare `iPhoneWorkoutSession` early so the
                // 3s countdown gives the BLE HR strap time to warm up before `start(at:)`.
                // No-op on iOS < 26 (legacy workoutManager path is used in that case).
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
                switch modeHolder.mode {
                case .watchPrimary:
                    // In Watch-primary mode iPhone has no active HKLiveWorkoutBuilder.
                    // ElapsedTracker interpolates sub-second precision from the last tick.
                    return elapsedTracker.elapsedAt(date)
                case .iPhoneStandalone:
                    return manager.builder?.elapsedTime(at: date) ?? 0
                }
            },
            togglePause: {
                await router.togglePause()
            },
            getWorkoutSummary: {
                switch modeHolder.mode {
                case .watchPrimary:
                    // Workout is saved by Watch; iPhone fetches it from HealthKit
                    // in handleWorkoutEndIOS and stores it in trainingManager.
                    return WorkoutSummary(workout: trainingManager.getWorkout(),
                                         metrics: trainingManager.getWorkoutMetrics())
                case .iPhoneStandalone:
                    return WorkoutSummary(workout: manager.getWorkout(),
                                         metrics: manager.getWorkoutMetrics())
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
                try await healthStore.delete(workout)
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
    /// No-op on iOS < 26 (legacy workoutManager path handles iPhone-standalone there).
    /// Called from `selectedWorkout` closure so the 3s countdown overlaps BLE strap warmup.
    func prepareIPhoneSession(activityType: HKWorkoutActivityType) async {
        guard #available(iOS 26.0, *) else {
            Logger.session.info("prepareIPhoneSession — iOS < 26, skipping (legacy workoutManager path)")
            return
        }
        do {
            _ = await authorizationManager.requestAuthorization()
            let configuration = HKWorkoutConfiguration()
            configuration.activityType = activityType
            configuration.locationType = .outdoor
            let new = iPhoneWorkoutSession(healthStore: healthStore, configuration: configuration)
            try await new.prepare()
            iPhoneSession = new
            Logger.session.info("prepareIPhoneSession — iPhoneWorkoutSession prepared (activityType: \(activityType.rawValue))")
        } catch {
            Logger.session.error("prepareIPhoneSession failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func togglePause() async {
        switch mode {
        case .watchPrimary:
            // Mirrored session pause propagates to Watch automatically via HealthKit.
            trainingManager.togglePause()
        case .iPhoneStandalone:
            // SP1 pragmatic: pause/resume routing stays on legacy `workoutManager.togglePause()`
            // even when iPhone-standalone uses `iPhoneWorkoutSession` for start/end. Full
            // togglePause through `iPhoneSession.pause()` / `.resume()` requires tracking
            // current session state inside this actor (AsyncStream.first blocks because
            // `iPhoneWorkoutSession.state` does not emit a baseline on subscription).
            // Deferred to a follow-up ticket — see WorkoutMirrorLive/CLAUDE.md R6 notes.
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
