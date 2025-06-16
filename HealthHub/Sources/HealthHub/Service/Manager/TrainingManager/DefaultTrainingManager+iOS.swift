//
//  DefaultTrainingManager+iOS.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/06/2025.
//

#if os(iOS)
import Foundation
import HealthKit
import SharedModels

// MARK: - iOS-specific Setup and Configuration
extension DefaultTrainingManager {
    
    /// Sets up the handler to receive mirrored sessions from Apple Watch (iOS only)
    public func setupRemoteSessionHandler() {
        print("📱 iOS: Setting up remote session handler")
        
        healthStore.workoutSessionMirroringStartHandler = { [weak self] mirroredSession in
            print("🎉 iOS: RECEIVED MIRRORED SESSION! State: \(mirroredSession.state)")
            Task { @MainActor in
                guard let self = self else { return }
                
                print("📱 iOS: Received mirrored session from Watch")
                
                // Reset current workout state
                self.resetWorkout()
                
                // Set up the mirrored session
                self.session = mirroredSession
                self.session?.delegate = self
                
                // Update running state
                self.workoutSessionIsRunning = mirroredSession.state == .running
                self.workoutSessionContinuation?.yield(self.workoutSessionIsRunning)
                
                print("📱 iOS: Mirrored session state: \(mirroredSession.state.rawValue)")
            }
        }
    }
    
    /// Starts a workout app on the paired Apple Watch
    public func startWatchWorkout(workoutType: HKWorkoutActivityType) async throws {
        print("📱 iOS: Starting workout on paired Watch")
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = workoutType
        configuration.locationType = .outdoor
        
        try await healthStore.startWatchApp(toHandle: configuration)
        print("✅ iOS: Successfully requested Watch to start workout")
    }
}

// MARK: - iOS-specific Data Handling
extension DefaultTrainingManager {
    
    /// Process various types of data received from Apple Watch
    internal func processReceivedWatchData(_ data: Data) throws {
        print("📱 iOS: Processing received data of size: \(data.count) bytes")
        
        // Try different data formats in order of likelihood
        
        // 1. Try WorkoutElapsedTime (for time synchronization)
        if let elapsedTime = try? JSONDecoder().decode(WorkoutElapsedTime.self, from: data) {
            handleElapsedTimeUpdate(elapsedTime)
            return
        }
        
        // 2. Try custom WorkoutMetrics (JSON format)
        if let receivedMetrics = try? JSONDecoder().decode(WorkoutMetrics.self, from: data) {
            handleWorkoutMetricsUpdate(receivedMetrics)
            return
        }
        
        // 3. Try HKStatistics array (HealthKit archived data)
        if let statisticsArray = try NSKeyedUnarchiver.unarchivedArrayOfObjects(ofClass: HKStatistics.self, from: data) {
            handleStatisticsUpdate(statisticsArray)
            return
        }
        
        // 4. Try single HKStatistics object
        if let statistics = try? NSKeyedUnarchiver.unarchivedObject(ofClass: HKStatistics.self, from: data) {
            handleStatisticsUpdate([statistics])
            return
        }
        
        print("⚠️ iOS: Received unrecognized data format")
    }
    
    // MARK: - Private Data Processing Methods
    
    private func handleElapsedTimeUpdate(_ elapsedTime: WorkoutElapsedTime) {
        var currentElapsedTime: TimeInterval = 0
        
        if session?.state == .running {
            currentElapsedTime = elapsedTime.timeInterval + Date().timeIntervalSince(elapsedTime.date)
        } else {
            currentElapsedTime = elapsedTime.timeInterval
        }
        
        print("📱 iOS: Updated elapsed time: \(currentElapsedTime)s")
        // TODO: Update your elapsed time property if you have one
        // self.elapsedTimeInterval = currentElapsedTime
    }
    
    private func handleWorkoutMetricsUpdate(_ receivedMetrics: WorkoutMetrics) {
        print("📱 iOS: Received WorkoutMetrics - HR: \(receivedMetrics.heartRate), Energy: \(receivedMetrics.activeEnergy)")
        
        self.metrics = receivedMetrics
        self.workoutMetricsContinuation?.yield(receivedMetrics)
    }
    
    private func handleStatisticsUpdate(_ statisticsArray: [HKStatistics]) {
        print("📱 iOS: Processing \(statisticsArray.count) HKStatistics objects")
        
        for statistics in statisticsArray {
            updateForStatistics(statistics)
        }
    }
}

// MARK: - iOS-specific Workout History
extension DefaultTrainingManager {
    
    /// Fetch today's workouts of a specific type
    public func fetchTodaysWorkouts(workoutType: HKWorkoutActivityType) async -> [HKWorkout] {
        print("📱 iOS: Fetching today's workouts for type: \(workoutType.rawValue)")
        
        let samples = try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day], from: .now)
            
            guard let startDate = calendar.date(from: components),
                  let endDate = calendar.date(byAdding: .day, value: 1, to: startDate) else {
                print("❌ iOS: Failed to create dates from: \(components)")
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
                    print("❌ iOS: Failed to run sample query: \(error)")
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples ?? [])
            }
            healthStore.execute(query)
        }
        
        let workouts = samples as? [HKWorkout] ?? []
        print("📱 iOS: Found \(workouts.count) workouts for today")
        return workouts
    }
    
    /// Fetch quantity collection for a specific workout
    public func fetchQuantityCollection(for workout: HKWorkout,
                                       quantityTypeIdentifier: HKQuantityTypeIdentifier,
                                       statisticsOptions: HKStatisticsOptions) async -> [HKStatistics] {
        
        print("📱 iOS: Fetching quantity collection for workout: \(quantityTypeIdentifier.rawValue)")
        
        let results = try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKStatistics], Error>) in
            let calendar = Calendar.current
            let interval = DateComponents(minute: 1)
            let components = DateComponents(calendar: calendar, timeZone: calendar.timeZone, second: 59)
            
            guard let anchorDate = calendar.nextDate(after: Date(),
                                                     matching: components,
                                                     matchingPolicy: .nextTime,
                                                     repeatedTimePolicy: .first,
                                                     direction: .backward) else {
                print("❌ iOS: Failed to calculate anchor date")
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
                    print("❌ iOS: Failed to run statistics collection query: \(error)")
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
        
        let statistics = results ?? []
        print("📱 iOS: Found \(statistics.count) statistics entries")
        return statistics
    }
}

#endif
