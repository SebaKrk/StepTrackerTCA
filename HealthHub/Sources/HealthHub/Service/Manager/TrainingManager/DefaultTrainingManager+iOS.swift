//
//  DefaultTrainingManager+iOS.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/06/2025.
//

#if os(iOS)
import Foundation
import HealthKit
import OSLog
import SharedModels

// MARK: - iOS-specific Setup and Configuration
extension DefaultTrainingManager {
    
    /// Sets up the handler to receive mirrored sessions from Apple Watch (iOS only)
    public func setupRemoteSessionHandler() {
        healthStore.workoutSessionMirroringStartHandler = { [weak self] mirroredSession in
            Logger.trainingManager.info("MIRRORED SESSION received — state: \(mirroredSession.state.rawValue)")
            Task { @MainActor in
                guard let self else { return }

                // Clear stale workout from previous session so SummaryFeature
                // doesn't display old data while handleWorkoutEndIOS polls HealthKit.
                self.workout = nil

                // Store mirrored session — do NOT reset other state; this session lives
                // alongside any existing state and is the Watch-primary source of truth.
                self.session = mirroredSession
                self.session?.delegate = self

                self.sessionState = mirroredSession.state
                self.workoutSessionIsRunning = mirroredSession.state == .running

                // Yield initial state to both streams.
                self.workoutSessionContinuation?.yield(self.workoutSessionIsRunning)
                self.workoutSessionStateContinuation?.yield(mirroredSession.state)

                // Apple Fitness-style startup flow signal — SessionFeature uses this
                // to transition from `.waitingForWatch` → `.countdown`.
                self.mirroredSessionStartedContinuation?.yield(())
            }
        }
    }

    /// One-shot signal stream — emit happens in `setupRemoteSessionHandler` when iPhone
    /// receives the mirrored session from Watch. Convention identical to
    /// `workoutSessionStateStream`: finish previous continuation, create fresh stream.
    public var mirroredSessionStartedStream: AsyncStream<Void> {
        mirroredSessionStartedContinuation?.finish()
        let (stream, continuation) = AsyncStream.makeStream(of: Void.self)
        mirroredSessionStartedContinuation = continuation
        return stream
    }
    
    /// Re-attaches an `HKWorkoutSession` recovered after iPhone app crash.
    ///
    /// Called from `AppDelegate.application(_:didFinishLaunchingWithOptions:)` via the
    /// always-try `recoverActiveWorkoutSession()` path. The recovered session may be
    /// `.primary` (iPhone-standalone iOS 26+ owned by `iPhoneWorkoutSession`) or
    /// `.mirroredFromRemoteDevice` (Watch-primary iPhone-side mirror managed here).
    ///
    /// `HKLiveWorkoutBuilder` and `HKLiveWorkoutDataSource` do NOT survive recovery for
    /// `.primary` sessions — they must be reattached or no further samples will be
    /// collected. For `.mirroredFromRemoteDevice` iPhone has no builder anyway (Watch
    /// owns it) — only the session reference and delegate need to be restored.
    public func recover(session: HKWorkoutSession) {
        Logger.trainingManager.info("[Recovery] re-attaching session (type=\(session.type.rawValue), state=\(session.state.rawValue))")

        self.session = session
        session.delegate = self

        if session.type == .primary {
            // `iPhoneWorkoutSession` is the canonical owner of primary sessions on iPhone.
            // Full rebuild of its internal builder + dataSource + continuation registries
            // requires bridging into that class — not yet wired. The session reference is
            // stored here so subscribers observe the state; sample collection awaits the
            // bridge.
            Logger.trainingManager.notice("[Recovery] primary session — iPhoneWorkoutSession bridge not yet wired")
        }

        self.sessionState = session.state
        self.workoutSessionIsRunning = session.state == .running
        self.workoutSessionContinuation?.yield(self.workoutSessionIsRunning)
        self.workoutSessionStateContinuation?.yield(session.state)

        Logger.trainingManager.info("[Recovery] state propagated to subscribers")
    }

    /// Starts a workout app on the paired Apple Watch
    public func startWatchWorkout(workoutType: HKWorkoutActivityType) async throws {
        Logger.trainingManager.info("startWatchApp — activityType: \(workoutType.rawValue)")
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = workoutType
        configuration.locationType = .outdoor
        try await healthStore.startWatchApp(toHandle: configuration)
        Logger.trainingManager.info("startWatchApp sent — waiting for mirrored session")
    }
}

// MARK: - iOS-specific Data Handling
extension DefaultTrainingManager {
    
    /// Process various types of data received from Apple Watch
    internal func processReceivedWatchData(_ data: Data) throws {
        // Try different data formats in order of likelihood

        // 1. Try WorkoutElapsedTime (for time synchronization)
        if let elapsedTime = try? JSONDecoder().decode(WorkoutElapsedTime.self, from: data) {
            Logger.trainingManager.debug("processReceivedWatchData → WorkoutElapsedTime: \(elapsedTime.timeInterval, format: .fixed(precision: 1))s")
            handleElapsedTimeUpdate(elapsedTime)
            return
        }

        // 2. Try custom WorkoutMetrics (JSON format)
        if let receivedMetrics = try? JSONDecoder().decode(WorkoutMetrics.self, from: data) {
            Logger.trainingManager.info("processReceivedWatchData → WorkoutMetrics: HR=\(receivedMetrics.heartRate, format: .fixed(precision: 0)) energy=\(receivedMetrics.activeEnergy, format: .fixed(precision: 1))")
            handleWorkoutMetricsUpdate(receivedMetrics)
            return
        }

        // 3. Try HKStatistics array (HealthKit archived data)
        if let statisticsArray = try NSKeyedUnarchiver.unarchivedArrayOfObjects(ofClass: HKStatistics.self, from: data) {
            Logger.trainingManager.info("processReceivedWatchData → HKStatistics[\(statisticsArray.count)]")
            handleStatisticsUpdate(statisticsArray)
            return
        }

        // 4. Try single HKStatistics object
        if let statistics = try? NSKeyedUnarchiver.unarchivedObject(ofClass: HKStatistics.self, from: data) {
            Logger.trainingManager.info("processReceivedWatchData → HKStatistics (single)")
            handleStatisticsUpdate([statistics])
            return
        }

        Logger.trainingManager.notice("processReceivedWatchData: unrecognized data format (\(data.count) bytes)")
    }
    
    // MARK: - Private Data Processing Methods
    
    private func handleElapsedTimeUpdate(_ elapsedTime: WorkoutElapsedTime) {
        // Elapsed time from Watch — currently unused (iPhone uses its own ElapsedTracker).
    }

    private func handleWorkoutMetricsUpdate(_ receivedMetrics: WorkoutMetrics) {
        self.metrics = receivedMetrics
        yieldWorkoutMetrics(receivedMetrics)
    }

    private func handleStatisticsUpdate(_ statisticsArray: [HKStatistics]) {
        for statistics in statisticsArray {
            updateForStatistics(statistics)
        }
    }
}

// MARK: - iOS-specific Workout History
extension DefaultTrainingManager {
    
    /// Fetch today's workouts of a specific type
    public func fetchTodaysWorkouts(workoutType: HKWorkoutActivityType) async -> [HKWorkout] {
        let samples = try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day], from: .now)

            guard let startDate = calendar.date(from: components),
                  let endDate = calendar.date(byAdding: .day, value: 1, to: startDate) else {
                continuation.resume(returning: [])
                return
            }
            
            let todayPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
            let workoutTypePredicate = HKQuery.predicateForWorkouts(with: workoutType)
            let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [todayPredicate, workoutTypePredicate])
            
            let sortByStartDate = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            
            let query = HKSampleQuery(sampleType: .workoutType(),
                                      predicate: compoundPredicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: [sortByStartDate]) { (query, samples, error) in
                if let error {
                    Logger.trainingManager.error("fetchTodaysWorkouts query failed: \(error)")
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples ?? [])
            }
            healthStore.execute(query)
        }
        return samples as? [HKWorkout] ?? []
    }
    
    /// Fetch quantity collection for a specific workout
    public func fetchQuantityCollection(for workout: HKWorkout,
                                       quantityTypeIdentifier: HKQuantityTypeIdentifier,
                                       statisticsOptions: HKStatisticsOptions) async -> [HKStatistics] {
        let results = try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKStatistics], Error>) in
            let calendar = Calendar.current
            let interval = DateComponents(minute: 1)
            let components = DateComponents(calendar: calendar, timeZone: calendar.timeZone, second: 59)

            guard let anchorDate = calendar.nextDate(after: Date(),
                                                     matching: components,
                                                     matchingPolicy: .nextTime,
                                                     repeatedTimePolicy: .first,
                                                     direction: .backward) else {
                continuation.resume(returning: [])
                return
            }

            let predicateForWorkout = HKQuery.predicateForObjects(from: workout)
            let quantityType = HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier)!

            let query = HKStatisticsCollectionQuery(quantityType: quantityType,
                                                    quantitySamplePredicate: predicateForWorkout,
                                                    options: statisticsOptions,
                                                    anchorDate: anchorDate,
                                                    intervalComponents: interval)

            query.initialResultsHandler = { (query, results, error) in
                if let error = error {
                    Logger.trainingManager.error("fetchQuantityCollection query failed: \(error)")
                    continuation.resume(throwing: error)
                    return
                }

                var collection = [HKStatistics]()
                results?.enumerateStatistics(from: workout.startDate, to: workout.endDate) { (statistics, stop) in
                    collection.append(statistics)
                }
                continuation.resume(returning: collection)
            }
            healthStore.execute(query)
        }
        return results ?? []
    }
}

#endif
