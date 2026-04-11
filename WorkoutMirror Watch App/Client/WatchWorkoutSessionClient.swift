//
//  WatchWorkoutSessionClient.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Sciuba on 05/04/2026.
//

import ComposableArchitecture
import HealthKit
import Foundation

/// TCA dependency that manages a `HKWorkoutSession` on Apple Watch.
///
/// Watch is **not** the HKWorkout owner — iPhone saves the canonical record
/// (WWDC25 iPhone-primary pattern). Watch runs its own `HKWorkoutSession`
/// exclusively to access the wrist HR sensor via `HKLiveWorkoutBuilder`,
/// then streams live BPM readings to iPhone via WatchConnectivity.
/// At end, the Watch session is discarded (`discardWorkout`) so no
/// duplicate appears in the Health app.
struct WatchWorkoutSessionClient: Sendable {

    /// Starts a `HKWorkoutSession` on Watch for accurate HR collection and
    /// returns an `AsyncStream<Double>` of live BPM readings.
    var startSession: @Sendable (_ activityType: HKWorkoutActivityType) async -> AsyncStream<Double>

    /// Ends the active session: stops collection, discards the builder (no HKWorkout saved), ends the session.
    var endSession: @Sendable () async -> Void
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

    /// Resolved by `HKWorkoutSessionDelegate` when session transitions to `.stopped`.
    /// Used to bridge the async gap between `stopActivity()` and the delegate callback.
    private var sessionStoppedContinuation: CheckedContinuation<Void, Never>?

    func start(activityType: HKWorkoutActivityType) async -> AsyncStream<Double> {
        let (stream, continuation) = AsyncStream.makeStream(
            of: Double.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        hrContinuation = continuation

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
            try await builder?.beginCollection(at: start)

            do {
                try await session?.startMirroringToCompanionDevice()
            } catch {
#if targetEnvironment(simulator)
                print("🔧 Simulator: Mirroring not available (expected)")
#else
                print("❌ watchOS: Unable to start mirroring: \(error.localizedDescription)")
#endif
            }
        } catch {
            print("❌ watchOS: Failed to start workout session: \(error)")
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
            print("⌚ [DEBUG] end() — session or builder already nil, skipping")
            return
        }

        print("⌚ [DEBUG] end() — step 1: stopActivityAndWait (state=\(session.state.rawValue))")
        await stopActivityAndWait(session)

        print("⌚ [DEBUG] end() — step 2: endCollection")
        do {
            try await builder.endCollection(at: .now)
            print("⌚ [DEBUG] end() — step 2: endCollection OK")
        } catch {
            print("❌ watchOS: endCollection failed: \(error)")
        }
        // Always discard — even if endCollection failed.
        // Apple requires calling finishWorkout() or discardWorkout() to complete
        // the builder. Without this, session.end() causes HealthKit to auto-save
        // a duplicate workout record.
        builder.discardWorkout()
        print("⌚ [DEBUG] end() — step 2: workout discarded")

        print("⌚ [DEBUG] end() — step 3: session.end()")
        session.end()
        print("⌚ [DEBUG] end() — done")
    }

    /// Calls `session.stopActivity()` and suspends until the delegate confirms `.stopped`.
    ///
    /// If the session is already stopped or ended (e.g. crash recovery), skips immediately
    /// to avoid hanging on a continuation that will never be resumed.
    private func stopActivityAndWait(_ session: HKWorkoutSession) async {
        guard session.state == .running || session.state == .paused else {
            print("⌚ [DEBUG] stopActivityAndWait — skipped, state=\(session.state.rawValue)")
            return
        }
        print("⌚ [DEBUG] stopActivityAndWait — calling stopActivity, waiting for .stopped")
        await withCheckedContinuation { continuation in
            sessionStoppedContinuation = continuation
            session.stopActivity(with: .now)
        }
        print("⌚ [DEBUG] stopActivityAndWait — delegate confirmed .stopped")
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
        print("⌚ [DEBUG] session state: \(fromState.rawValue) → \(toState.rawValue)")
        guard toState == .stopped else { return }
        sessionStoppedContinuation?.resume()
        sessionStoppedContinuation = nil
    }

    func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {
        print("❌ watchOS: Workout session failed: \(error)")
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
