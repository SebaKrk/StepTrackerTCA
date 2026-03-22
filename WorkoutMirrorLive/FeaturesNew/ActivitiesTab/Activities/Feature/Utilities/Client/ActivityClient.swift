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
    
    /// Fetches user's maximum heart rate based on age and biological sex.
    ///
    /// Uses Fairbarn formula appropriate for user's biological sex.
    /// - Returns: Max heart rate in BPM, or nil if age is unavailable
    public var fetchMaxHeartRate: @Sendable () async -> Double?
    
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
}

extension ActivityClient: DependencyKey {
    public static let liveValue: ActivityClient = {

        @Dependency(\.activityManager) var activityManager
        @Dependency(\.personalDataManager) var personalDataManager
        @Dependency(\.heartRateCalculator) var heartRateCalculator
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
            fetchMaxHeartRate: {
                guard let age = try? await personalDataManager.getAge(),
                      let biologicalSex = try? await personalDataManager.getBiologicalSex()
                else {
                    return nil
                }
                
                let maxHR = heartRateCalculator.calculateMaxHeartRate(
                    age: age,
                    biologicalSex: biologicalSex
                )
                return Double(maxHR)
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
            }
        )
    }()
    
    public static let testValue = ActivityClient(
        fetchWorkouts: unimplemented("ActivityClient.fetchWorkouts", placeholder: []),
        fetchMaxHeartRate: unimplemented("ActivityClient.fetchMaxHeartRate", placeholder: nil),
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
        fetchWorkoutById: unimplemented("ActivityClient.fetchWorkoutById", placeholder: nil)
    )
}

extension DependencyValues {
    public var activityClient: ActivityClient {
        get { self[ActivityClient.self] }
        set { self[ActivityClient.self] = newValue }
    }
}
