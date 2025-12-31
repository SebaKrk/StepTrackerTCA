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
    
    public var fetchMETs: @Sendable (HKWorkout, Double) async throws -> Double?
}

extension ActivityClient: DependencyKey {
    public static let liveValue: ActivityClient = {
        
        @Dependency(\.activityManager) var activityManager
        @Dependency(\.personalDataManager) var personalDataManager
        @Dependency(\.heartRateCalculator) var heartRateCalculator
        @Dependency(\.workoutZoneAnalyzer) var zoneAnalyzer
        
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
            fetchMETs: { workout, weightKg in
                guard weightKg > 0,
                      workout.duration > 0,
                      let activeCalories = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?
                          .sumQuantity()?
                          .doubleValue(for: .kilocalorie()),
                      activeCalories > 0
                else {
                    return nil
                }
                
                let durationHours = workout.duration / 3600
                return activeCalories / (weightKg * durationHours)
            }
        )
    }()
    
    public static let testValue = ActivityClient(
        fetchWorkouts: unimplemented("ActivityClient.fetchWorkouts", placeholder: []),
        fetchMaxHeartRate: unimplemented("ActivityClient.fetchMaxHeartRate", placeholder: nil),
        analyzeWorkoutZones: unimplemented("ActivityClient.analyzeWorkoutZones", placeholder: nil),
        fetchZoneDistribution: unimplemented("ActivityClient.fetchZoneDistribution", placeholder: [:]),
        fetchMETs: unimplemented("ActivityClient.fetchMETs", placeholder: nil)
    )
}

extension DependencyValues {
    public var activityClient: ActivityClient {
        get { self[ActivityClient.self] }
        set { self[ActivityClient.self] = newValue }
    }
}
