//
//  DefaultWorkoutManager.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 12/08/2025.
//

import HealthKit
import OSLog
import SharedModels

@available(iOS 26.0, *)
public final class DefaultWorkoutManager: NSObject, WorkoutManager, @unchecked Sendable {

    // MARK: - HealthKit Configuration
    let healthStore: HKHealthStore

    // MARK: - Workout Session State
    var session: HKWorkoutSession?

    public var sessionState: HKWorkoutSessionState = .notStarted

    public var builder: HKLiveWorkoutBuilder?

    var workout: HKWorkout?

    var selectedWorkout: HKWorkoutActivityType? {
        didSet {
            guard let selectedWorkout = selectedWorkout else { return }

            Task {
               try await prepareWorkout(workoutType: selectedWorkout)
            }
        }
    }

    var showingSummaryView: Bool = false {
        didSet {
            if showingSummaryView == false {
                resetWorkout()
            }
        }
    }

    var workoutSessionIsRunning: Bool = false

    // MARK: - Workout Metrics
    var metrics = WorkoutMetrics(
        averageHeartRate: 0,
        heartRate: 0,
        activeEnergy: 0
    )

    // MARK: - AsyncStream — internal FIFO queue for serialised state-change handling
    //
    // Swift actors don't guarantee FIFO execution order. The stream ensures
    // that endCollection/finishWorkout always runs *after* the TCA reducer
    // has received the .stopped event — preventing the summary race condition.
    //
    // bufferingOldest(5): guarantees .stopped is NOT dropped when .ended arrives
    // immediately after. bufferingNewest(1) could discard .stopped, skipping
    // the endCollection → finishWorkout chain in consumeStateChange.
    let stateChangeTuple = AsyncStream.makeStream(
        of: (HKWorkoutSessionState, Date).self,
        bufferingPolicy: .bufferingOldest(5)
    )

    // MARK: - AsyncStream — external consumer streams (one active at a time)
    var workoutMetricsContinuation: AsyncStream<WorkoutMetrics>.Continuation?
    var workoutSessionContinuation: AsyncStream<HKWorkoutSessionState>.Continuation?

    // MARK: - Lifecycle

    public init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
        super.init()

        // Consume the FIFO queue: handles .stopped → endCollection → finishWorkout → session.end()
        Task { @MainActor [weak self] in
            guard let self else { return }
            for await (state, date) in stateChangeTuple.stream {
                await self.consumeStateChange(state: state, date: date)
            }
        }
    }

    // MARK: - TrainingManager Protocol Implementation

    public func setSelectedWorkout(_ type: HKWorkoutActivityType?) {
        print("🏃 [DefaultWorkoutManager] setSelectedWorkout: \(type?.rawValue ?? 0)")
        selectedWorkout = type
    }

    public func setValueForSummaryView(_ value: Bool) {
        showingSummaryView = value
    }

    public var workoutSessionStateStream: AsyncStream<HKWorkoutSessionState> {
        // Finish the previous subscription before handing out a new stream,
        // so stale TCA effects don't receive events from a dead session.
        workoutSessionContinuation?.finish()
        let (stream, continuation) = AsyncStream.makeStream(
            of: HKWorkoutSessionState.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        workoutSessionContinuation = continuation
        print("📡 [DefaultWorkoutManager] workoutSessionStateStream subscribed — initial state: \(sessionState.rawValue)")
        continuation.yield(sessionState)
        return stream
    }

    public var workoutMetricsStream: AsyncStream<WorkoutMetrics> {
        workoutMetricsContinuation?.finish()
        let (stream, continuation) = AsyncStream.makeStream(
            of: WorkoutMetrics.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        workoutMetricsContinuation = continuation
        return stream
    }

    public func getWorkout() -> HKWorkout? {
        workout
    }

    public func getWorkoutMetrics() -> WorkoutMetrics {
        metrics
    }

    // MARK: - Workout Management
    func prepareWorkout(workoutType: HKWorkoutActivityType) async throws {

        // Reset per-session state so second/third runs start clean.
        workout = nil
        workoutSessionIsRunning = false
        metrics = WorkoutMetrics(averageHeartRate: 0, heartRate: 0, activeEnergy: 0)

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = workoutType
        configuration.locationType = .indoor

        sessionState = .prepared

        session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
        builder = session?.associatedWorkoutBuilder()
        session?.delegate = self
        builder?.delegate = self
        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                      workoutConfiguration: configuration)

        session?.prepare()
        print("✅ [DefaultWorkoutManager] prepareWorkout complete — session: \(session != nil), builder: \(builder != nil)")
    }

    public func startWorkout() async {
        print("🚀 [DefaultWorkoutManager] startWorkout() called — session: \(session != nil)")
        guard session != nil else {
            print("❌ [DefaultWorkoutManager] startWorkout FAILED — no session prepared. Was selectedWorkout() called first?")
            return
        }

        let start = Date()
        print("▶️ [DefaultWorkoutManager] calling session.startActivity()")
        session?.startActivity(with: start)
        // sessionState is updated exclusively by the HKWorkoutSessionDelegate callback —
        // setting it here would cause a duplicate yield and potential race condition.

        do {
            try await builder?.beginCollection(at: start)
            print("✅ [DefaultWorkoutManager] beginCollection succeeded")
        } catch {
            print("❌ iOS: Error starting workout collection: \(error.localizedDescription)")
            sessionState = .notStarted
        }
    }

    internal func sendData(_ data: Data) async {
        do {
            try await session?.sendToRemoteWorkoutSession(data: data)
        } catch {
            let nsError = error as NSError

            if nsError.domain == "com.apple.healthkit" && nsError.code == 300 {
#if targetEnvironment(simulator)
                print("🔧 Simulator: Remote device communication not available (expected)")
#else
                print("❌ Failed to send data: \(error)")
#endif
            } else {
                print("❌ Failed to send data: \(error)")
            }
        }
    }

    // MARK: - Workout Data Handling

    internal func updateForStatistics(_ statistics: HKStatistics?) {
        guard let statistics = statistics else { return }

        switch statistics.quantityType {
        case HKQuantityType.quantityType(forIdentifier: .heartRate):
            let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            self.metrics.heartRate = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
            self.metrics.averageHeartRate = statistics.averageQuantity()?.doubleValue(for: heartRateUnit) ?? 0
            print("❤️ [DefaultWorkoutManager] HR: \(Int(self.metrics.heartRate)) bpm (avg: \(Int(self.metrics.averageHeartRate)))")

        case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
            let energyUnit = HKUnit.kilocalorie()
            self.metrics.activeEnergy = statistics.sumQuantity()?.doubleValue(for: energyUnit) ?? 0
            print("🔥 [DefaultWorkoutManager] Energy: \(String(format: "%.1f", self.metrics.activeEnergy)) kcal")

        default:
            print("📊 [DefaultWorkoutManager] Unknown type: \(statistics.quantityType.identifier)")
            return
        }

        let currentMetrics = self.metrics
        self.workoutMetricsContinuation?.yield(currentMetrics)
    }

    // MARK: - FIFO State Consumer

    /// Serialised handler for HealthKit session state changes.
    ///
    /// Only processes `.stopped` — all other states are handled in the delegate.
    /// Running on `@MainActor` ensures thread-safe access to `builder` / `session`.
    @MainActor
    private func consumeStateChange(state: HKWorkoutSessionState, date: Date) async {
        Logger.trainingManager.info("consumeStateChange: \(state.rawValue)")
        guard state == .stopped else { return }

        // iPhone is always the canonical HKWorkout owner (WWDC25 iPhone-primary architecture).
        // Watch discards its own session — only one HKWorkout is saved.
        guard let builder else { return }
        Logger.trainingManager.info(".stopped → endCollection → finishWorkout → session.end()")
        do {
            try await builder.endCollection(at: date)
            Logger.trainingManager.info("endCollection done")
            let finishedWorkout = try await builder.finishWorkout()
            self.workout = finishedWorkout
            let workoutId = finishedWorkout?.uuid.uuidString ?? "nil"
            await WorkoutFileLogger.shared.log("WORKOUT SAVED (iPhone) — id: \(workoutId)")
            self.session?.end()
            self.sessionState = .ended
            self.workoutSessionContinuation?.yield(.ended)
            await WorkoutFileLogger.shared.log("SESSION ENDED — .ended yielded to TCA")
            Logger.trainingManager.info("session ended, .ended yielded to TCA")
        } catch {
            Logger.trainingManager.error("finishWorkout failed: \(error)")
        }
    }

    // MARK: - Watch HR Integration

    /// Resets the internal heart-rate value to 0 so that subsequent HealthKit
    /// energy/calorie updates do not re-broadcast a stale HR through the metrics
    /// stream. Called by the Watch HR watchdog when WatchConnectivity goes silent.
    public func resetWatchHeartRate() {
        metrics.heartRate = 0
        workoutMetricsContinuation?.yield(metrics)
        print("⏱️ [DefaultWorkoutManager] resetWatchHeartRate — metrics.heartRate set to 0")
    }

    /// Adds a single heart-rate sample (received from Watch via WatchConnectivity)
    /// to the live workout builder so it appears in the saved HKWorkout.
    public func addHeartRateSample(_ bpm: Double, at date: Date) async {
        guard let builder else { return }
        let hrType = HKQuantityType(.heartRate)
        let bpmUnit = HKUnit.count().unitDivided(by: .minute())
        let quantity = HKQuantity(unit: bpmUnit, doubleValue: bpm)
        let sample = HKQuantitySample(type: hrType, quantity: quantity, start: date, end: date)
        do {
            _ = try await builder.addSamples([sample])
        } catch {
            print("⚠️ [DefaultWorkoutManager] addHeartRateSample failed: \(error)")
        }
    }

    // MARK: - Helpers

    func resetWorkout() {
        selectedWorkout = nil
        builder = nil
        workout = nil
        session = nil
        metrics = WorkoutMetrics(
            averageHeartRate: 0,
            heartRate: 0,
            activeEnergy: 0
        )
        workoutSessionIsRunning = false
        sessionState = .notStarted
    }
}
