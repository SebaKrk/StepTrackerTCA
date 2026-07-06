//
//  DefaultTrainingManager.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 28/05/2025.
//

import HealthKit
import OSLog
import SharedModels

public final class DefaultTrainingManager: NSObject, TrainingManager, @unchecked Sendable {

    // MARK: - HealthKit Configuration
    let healthStore: HKHealthStore
    
    // MARK: - Workout Session State
    var session: HKWorkoutSession?
    
    public var sessionState: HKWorkoutSessionState = .notStarted
    
#if os(watchOS)
    public var builder: HKLiveWorkoutBuilder?
#endif
    
    var workout: HKWorkout?
    
#if os(watchOS)
    var selectedWorkout: HKWorkoutActivityType? {
        didSet {
            guard let selectedWorkout = selectedWorkout else { return }
            
            Task {
               try await prepareWorkout(workoutType: selectedWorkout)
            }
        }
    }
#else
    var selectedWorkout: HKWorkoutActivityType?
#endif
    
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
    
    // Multicast: each `workoutMetricsStream` subscriber gets its own continuation.
    // Multiple features observe metrics at the same time (LiveSession + IPAD-0087 Gym Room).
    var workoutMetricsContinuations: [UUID: AsyncStream<WorkoutMetrics>.Continuation] = [:]
    var workoutSessionContinuation: AsyncStream<Bool>.Continuation?
    var workoutSessionStateContinuation: AsyncStream<HKWorkoutSessionState>.Continuation?

    #if os(iOS)
    /// Single-shot signal — emitted from `workoutSessionMirroringStartHandler` when iPhone
    /// receives the mirrored session from Apple Watch. Stored here (not in `+iOS` extension)
    /// because Swift does not allow stored properties in extensions.
    var mirroredSessionStartedContinuation: AsyncStream<Void>.Continuation?

    /// Multicast: mirroring-link connection status subscribers (IOS-00098-G).
    /// `.lost` on `didDisconnectFromRemoteDeviceWithError`, `.connected` when the
    /// system reconnect delivers a fresh mirrored session via the start handler.
    ///
    /// Guarded by `watchConnectionLock` — subscriptions come from TCA `.run` effects
    /// (background executor), yields/cleanup from the main actor and stream
    /// terminations. Same pattern as `DefaultWatchConnectivityManager.eventContinuations`.
    var watchConnectionContinuations: [UUID: AsyncStream<WatchMirroringConnectionStatus>.Continuation] = [:]

    /// Lock protecting `watchConnectionContinuations` across executors.
    let watchConnectionLock = NSLock()
    #endif
    
    // MARK: - Lifecycle
    public init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
        super.init()
#if os(iOS)
        setupRemoteSessionHandler()
#endif
    }
    
    // MARK: - TrainingManager Protocol Implementation
    
    public func setSelectedWorkout(_ type: HKWorkoutActivityType?) {
        selectedWorkout = type
    }
    
    public func setValueForSummaryView(_ value: Bool) {
        showingSummaryView = value
    }
    
    public func workoutSessionIsRunningStream() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            self.workoutSessionContinuation = continuation
            continuation.yield(self.workoutSessionIsRunning)
        }
    }
    
    public var workoutMetricsStream: AsyncStream<WorkoutMetrics> {
        let id = UUID()
        let (stream, continuation) = AsyncStream.makeStream(of: WorkoutMetrics.self)
        continuation.onTermination = { [weak self] _ in
            self?.workoutMetricsContinuations.removeValue(forKey: id)
        }
        workoutMetricsContinuations[id] = continuation
        return stream
    }

    /// Multicast yield — delivers metrics to all active subscribers.
    func yieldWorkoutMetrics(_ metrics: WorkoutMetrics) {
        for continuation in workoutMetricsContinuations.values {
            continuation.yield(metrics)
        }
    }

    public var workoutSessionStateStream: AsyncStream<HKWorkoutSessionState> {
        workoutSessionStateContinuation?.finish()
        let (stream, continuation) = AsyncStream.makeStream(
            of: HKWorkoutSessionState.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        workoutSessionStateContinuation = continuation
        // Emit current state immediately so subscriber has a baseline.
        continuation.yield(sessionState)
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
#if os(watchOS)
        print("⌚ watchOS: Starting workout: \(workoutType)")
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = workoutType
        configuration.locationType = .outdoor
        
        sessionState = .prepared

        session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
        builder = session?.associatedWorkoutBuilder()
        session?.delegate = self
        builder?.delegate = self
        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                      workoutConfiguration: configuration)

        session?.prepare()
#else
        print("❌ iOS: Unable to start")
#endif
    }
    
    
    
    public func startWorkout() async {
        guard session != nil else {
            print("❌ No workout session prepared")
            return
        }
#if os(watchOS)
        do {
            print("⌚ watchOS: Starting mirroring to companion device")
            try await session?.startMirroringToCompanionDevice()
            print("✅ watchOS: Mirroring started successfully")
        } catch {
#if targetEnvironment(simulator)
            print("🔧 Simulator: Mirroring not available (expected in simulator)")
#else
            print("❌ watchOS: Unable to start mirrored workout: \(error.localizedDescription)")
#endif
        }
        
        let start = Date()
        session?.startActivity(with: start)
        sessionState = .running
        
        await withCheckedContinuation { continuation in
            builder?.beginCollection(withStart: start) { (success, error) in
                if success {
                    print("✅ watchOS: Workout collection started successfully")
                } else {
                    print("❌ watchOS: Error starting workout collection: \(error?.localizedDescription ?? "Unknown")")
                }
                continuation.resume()
            }
        }
#endif
    }


    /// Returns `true` when HealthKit confirmed the send, `false` on failure/timeout —
    /// critical callers (iPhone-initiated End) branch on the result instead of
    /// fire-and-forget (IOS-00098 review, cluster D).
    @discardableResult
    internal func sendData(_ data: Data) async -> Bool {
        do {
            // Guarded variant (SharedModels) — hard timeout against Apple bug #769355
            // where the native async send never resumes.
            guard let session else {
                // This result decides the dismiss after End (delivery-aware, cluster D) —
                // it must be in the file report, not in a print() visible only under Xcode.
                Logger.trainingManager.error("sendData — no session attached (\(data.count) bytes dropped)")
                await WorkoutFileLogger.shared.log("[Send] SKIPPED — no mirrored session attached")
                return false
            }
            try await session.sendToRemoteWorkoutSession(data: data, timeout: 3)
            Logger.trainingManager.debug("sendData — delivered \(data.count) bytes")
            return true
        } catch {
            let nsError = error as NSError
#if targetEnvironment(simulator)
            if nsError.domain == "com.apple.healthkit" && nsError.code == 300 {
                // Mirroring does not work in simulators (DTS) — expected noise.
                Logger.trainingManager.debug("sendData — simulator, mirroring unavailable (expected)")
                return false
            }
#endif
            // The wrapper logs every failed attempt to the file ("[Send] attempt 1 failed…");
            // the FINAL verdict after exhausting retries lands here.
            Logger.trainingManager.error("sendData — FAILED after retry: \(error.localizedDescription)")
            await WorkoutFileLogger.shared.log("[Send] FAILED after retry — \(error.localizedDescription)")
            return false
        }
    }

    #if os(iOS)
    /// Public surface for the HK mirroring channel send. Forwards to internal `sendData`.
    /// Used by SessionFeature for lifecycle events (e.g. `.workoutEnded`) — delivery
    /// is reliable regardless of WatchConnectivity reachability.
    @discardableResult
    public func sendDataToWatch(_ data: Data) async -> Bool {
        await sendData(data)
    }
    #endif
    
    // MARK: - Workout Data Handling
    
    internal func updateForStatistics(_ statistics: HKStatistics?) {
        guard let statistics = statistics else { return }
        
        switch statistics.quantityType {
        case HKQuantityType.quantityType(forIdentifier: .heartRate):
            let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            self.metrics.heartRate = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
            self.metrics.averageHeartRate = statistics.averageQuantity()?.doubleValue(for: heartRateUnit) ?? 0
            
        case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
            let energyUnit = HKUnit.kilocalorie()
            self.metrics.activeEnergy = statistics.sumQuantity()?.doubleValue(for: energyUnit) ?? 0
            
        default:
            return
        }
        
        // Yield updated metrics to stream
        let currentMetrics = self.metrics
        yieldWorkoutMetrics(currentMetrics)
    }
    
    // MARK: - Helpers
    
    func resetWorkout() {
        print("🔄 Resetting workout state")
        selectedWorkout = nil
#if os(watchOS)
        builder = nil
#endif
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


//    internal func startWorkout(workoutType: HKWorkoutActivityType) async {
//    public func startWorkout() async {
        
//        print("⌚ watchOS: Starting workout: \(workoutType)")
//
//        let configuration = HKWorkoutConfiguration()
//        configuration.activityType = workoutType
//        configuration.locationType = .outdoor
        
//        do {
//            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
//            builder = session?.associatedWorkoutBuilder()
//        } catch {
//            print("❌ watchOS: Error creating workout session: \(error)")
//            return
//        }
//
//        session?.delegate = self
//        builder?.delegate = self
//        builder?.dataSource = HKLiveWorkoutDataSource(
//            healthStore: healthStore,
//            workoutConfiguration: configuration
//        )
        


