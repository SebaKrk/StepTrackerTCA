//
//  ActivityClient.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 13/12/2025.
//

import ComposableArchitecture
import HealthKit
import HealthHub
import SharedModels
import CoreLocation

public struct ActivityClient: Sendable {
    
    /// Fetches workouts from the specified time period.
    public var fetchWorkouts: @Sendable (Int, ActivitiesSortOption) async throws -> [HKWorkout]

    /// Analyzes heart rate zones for a specific workout.
    ///
    /// - Parameters:
    ///   - workout: The workout to analyze
    ///   - maxHeartRate: User's maximum heart rate for zone calculation
    /// - Returns: PrimaryZoneInfo with dominant zone and duration, or nil if no HR data
    public var analyzeWorkoutZones: @Sendable (HKWorkout, Double) async throws -> PrimaryZoneInfo?
    
    /// Returns full zone distribution for a workout.
    public var fetchZoneDistribution: @Sendable (HKWorkout, Double) async throws -> [HeartRateZone: TimeInterval]
    
    /// Fetches METs for a workout. Weight is automatically retrieved from workout date.
    public var fetchMETs: @Sendable (HKWorkout) async throws -> Double?
    
    /// Fetches TRIMP for a workout.
    public var fetchTRIMP: @Sendable (HKWorkout, Double) async throws -> Double
    
    /// Fetches hrTSS for a workout.
    public var fetchHRTSS: @Sendable (HKWorkout, Double) async throws -> Double?
    
    /// Fetches HR Recovery (1 min) for a workout.
    public var fetchHRRecovery: @Sendable (HKWorkout) async throws -> Int?
    
    /// Fetches Intensity Factor (IF) for a workout.
    public var fetchIntensityFactor: @Sendable (HKWorkout, Double) async throws -> Double?
    
    /// Fetches Recovery Demand for a workout.
    public var fetchRecoveryDemand: @Sendable (HKWorkout, Double) async throws -> RecoveryDemand?
    
    /// Fetches GPS route for a workout.
    /// Returns empty array if no route data available.
    public var fetchWorkoutRoute: @Sendable (HKWorkout) async throws -> [CLLocation]
    
    /// Fetches start location for a workout.
    /// Returns nil if no route data available.
    public var fetchWorkoutStartLocation: @Sendable (HKWorkout) async throws -> CLLocationCoordinate2D?

    /// Fetches a single workout by its HealthKit UUID.
    /// Returns nil if no matching workout is found.
    public var fetchWorkoutById: @Sendable (UUID) async throws -> HKWorkout?

    /// Deletes the given workout from HealthKit.
    /// Only works for workouts created by this app.
    public var deleteWorkout: @Sendable (HKWorkout) async throws -> Void

    /// Push-based change signal: emits whenever the HealthKit workout collection
    /// changes (a new workout lands — e.g. Watch→iPhone sync completes — or one is
    /// deleted). The initial snapshot is skipped, so every emission is a real change.
    /// Wzorzec R5 (`HKAnchoredObjectQueryDescriptor.results(for:)`) — subscribers
    /// refetch on emission instead of polling.
    public var observeWorkoutChanges: @Sendable () -> AsyncStream<Void>
}

extension ActivityClient: DependencyKey {
    public static let liveValue: ActivityClient = {

        @Dependency(\.activityManager) var activityManager
        @Dependency(\.workoutZoneAnalyzer) var zoneAnalyzer
        @Dependency(\.workoutMetricsManager) var metricsManager
        @Dependency(\.workoutLocationManager) var locationManager
        @Dependency(\.healthStore) var healthStore

        return ActivityClient(
            fetchWorkouts: { days, sortOption in
                try await activityManager.fetchWorkouts(
                    for: days,
                    sortBy: sortOption
                )
            },
            analyzeWorkoutZones: { workout, maxHeartRate in
                let samples = try await activityManager.fetchHeartRateSamples(
                    for: workout
                )
                
                return zoneAnalyzer.analyzePrimaryZone(
                    samples: samples,
                    maxHeartRate: maxHeartRate
                )
            },
            fetchZoneDistribution: { workout, maxHeartRate in
                let samples = try await activityManager.fetchHeartRateSamples(for: workout)
                return zoneAnalyzer.calculateZoneDistribution(
                    samples: samples,
                    maxHeartRate: maxHeartRate
                )
            },
            
            // MARK: - Workout Metrics (delegated to manager)
            
            fetchMETs: { workout in
                try await metricsManager.fetchMETs(for: workout)
            },
            fetchTRIMP: { workout, maxHeartRate in
                try await metricsManager.fetchTRIMP(for: workout, maxHeartRate: maxHeartRate)
            },
            fetchHRTSS: { workout, maxHeartRate in
                try await metricsManager.fetchHRTSS(for: workout, maxHeartRate: maxHeartRate)
            },
            fetchHRRecovery: { workout in
                try await metricsManager.fetchHRRecovery(for: workout)
            },
            fetchIntensityFactor: { workout, maxHeartRate in
                try await metricsManager.fetchIntensityFactor(for: workout, maxHeartRate: maxHeartRate)
            },
            fetchRecoveryDemand: { workout, maxHeartRate in
                try await metricsManager.fetchRecoveryDemand(for: workout, maxHeartRate: maxHeartRate)
            },
            
            // MARK: - Workout Location
            
            fetchWorkoutRoute: { workout in
                try await locationManager.fetchWorkoutRoute(workout)
            },
            fetchWorkoutStartLocation: { workout in
                try await locationManager.fetchWorkoutStartLocation(workout)
            },
            fetchWorkoutById: { uuid in
                try await withCheckedThrowingContinuation { continuation in
                    let predicate = HKQuery.predicateForObject(with: uuid)
                    let query = HKSampleQuery(
                        sampleType: .workoutType(),
                        predicate: predicate,
                        limit: 1,
                        sortDescriptors: nil
                    ) { _, samples, error in
                        if let error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: samples?.first as? HKWorkout)
                        }
                    }
                    healthStore.execute(query)
                }
            },
            deleteWorkout: { workout in
                try await healthStore.delete(workout)
            },
            observeWorkoutChanges: {
                AsyncStream { continuation in
                    let task = Task {
                        let descriptor = HKAnchoredObjectQueryDescriptor(
                            predicates: [.workout()],
                            anchor: nil
                        )
                        do {
                            var isInitialSnapshot = true
                            for try await _ in descriptor.results(for: healthStore) {
                                // Pierwsza emisja to pełny snapshot istniejących workoutów —
                                // pomijamy, subskrybent interesuje się tylko ZMIANAMI.
                                if isInitialSnapshot {
                                    isInitialSnapshot = false
                                    continue
                                }
                                continuation.yield(())
                            }
                        } catch {
                            // Query padło (np. cofnięte uprawnienia) — kończymy stream,
                            // subskrybent zostaje przy triggerach manualnych (pull-to-refresh).
                        }
                        continuation.finish()
                    }
                    continuation.onTermination = { _ in task.cancel() }
                }
            }
        )
    }()
    
    public static let testValue = ActivityClient(
        fetchWorkouts: unimplemented("ActivityClient.fetchWorkouts", placeholder: []),
        analyzeWorkoutZones: unimplemented("ActivityClient.analyzeWorkoutZones", placeholder: nil),
        fetchZoneDistribution: unimplemented("ActivityClient.fetchZoneDistribution", placeholder: [:]),
        fetchMETs: unimplemented("ActivityClient.fetchMETs", placeholder: nil),
        fetchTRIMP: unimplemented("ActivityClient.fetchTRIMP", placeholder: 0),
        fetchHRTSS: unimplemented("ActivityClient.fetchHRTSS", placeholder: nil),
        fetchHRRecovery: unimplemented("ActivityClient.fetchHRRecovery", placeholder: nil),
        fetchIntensityFactor: unimplemented("ActivityClient.fetchIntensityFactor", placeholder: nil),
        fetchRecoveryDemand: unimplemented("ActivityClient.fetchRecoveryDemand", placeholder: nil),
        fetchWorkoutRoute: unimplemented("ActivityClient.fetchWorkoutRoute", placeholder: []),
        fetchWorkoutStartLocation: unimplemented("ActivityClient.fetchWorkoutStartLocation", placeholder: nil),
        fetchWorkoutById: unimplemented("ActivityClient.fetchWorkoutById", placeholder: nil),
        deleteWorkout: unimplemented("ActivityClient.deleteWorkout"),
        observeWorkoutChanges: unimplemented(
            "ActivityClient.observeWorkoutChanges",
            placeholder: { AsyncStream { $0.finish() } }()
        )
    )
}

extension DependencyValues {
    public var activityClient: ActivityClient {
        get { self[ActivityClient.self] }
        set { self[ActivityClient.self] = newValue }
    }
}
