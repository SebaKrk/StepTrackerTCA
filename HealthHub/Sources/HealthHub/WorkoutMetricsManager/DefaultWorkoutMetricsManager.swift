//
//  DefaultWorkoutMetricsManager.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 31/12/2025.
//

import ComposableArchitecture
import Foundation
import HealthKit
import SharedModels

public final class DefaultWorkoutMetricsManager: WorkoutMetricsManager, @unchecked Sendable {
    
    // MARK: - Dependencies
    
    @Dependency(\.workoutMetricsCalculator) var calculator
    @Dependency(\.personalDataManager) var personalDataManager
    @Dependency(\.activityManager) var activityManager
    @Dependency(\.workoutZoneAnalyzer) var zoneAnalyzer
    
    // MARK: - Lifecycle
    
    public init() {}
    
    // MARK: - Single Workout Metrics
    
    public func fetchMETs(for workout: HKWorkout) async throws -> Double? {
        // Pobierz wagę z dnia treningu
        guard let weightData = try await personalDataManager.getWeight(for: workout.startDate),
              weightData.value > 0
        else {
            print("⚠️ WorkoutMetricsManager: No weight data for \(workout.startDate)")
            return nil
        }
        
        // Pobierz kalorie
        guard let activeCalories = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?
            .sumQuantity()?
            .doubleValue(for: .kilocalorie()),
              activeCalories > 0
        else {
            print("⚠️ WorkoutMetricsManager: No calorie data for workout")
            return nil
        }
        
        // Oblicz w kalkulatorze
        return calculator.calculateMETs(
            activeCalories: activeCalories,
            weightKg: weightData.value,
            durationSeconds: workout.duration
        )
    }
    
    public func fetchTRIMP(for workout: HKWorkout, maxHeartRate: Double) async throws -> Double {
        let samples = try await activityManager.fetchHeartRateSamples(for: workout)
        
        let zoneDistribution = zoneAnalyzer.calculateZoneDistribution(
            samples: samples,
            maxHeartRate: maxHeartRate
        )
        
        return calculator.calculateTRIMP(zoneDistribution: zoneDistribution)
    }
    
    public func fetchHRTSS(for workout: HKWorkout, maxHeartRate: Double) async throws -> Double? {
        // Pobierz resting HR z dnia treningu
        guard let restingHRData = try await personalDataManager.getRestingHeartRate(for: workout.startDate),
              restingHRData.value > 0
        else {
            print("⚠️ WorkoutMetricsManager: No resting HR data for \(workout.startDate)")
            return nil
        }
        
        // Pobierz avg HR z treningu
        guard let avgHR = workout.statistics(for: HKQuantityType(.heartRate))?
            .averageQuantity()?
            .doubleValue(for: .count().unitDivided(by: .minute()))
        else {
            print("⚠️ WorkoutMetricsManager: No average HR for workout")
            return nil
        }
        
        // Pobierz TRIMP
        //let trimp = try await fetchTRIMP(for: workout, maxHeartRate: maxHeartRate)
        
        let durationMinutes = workout.duration / 60
        
        return calculator.calculateHRTSS(
            avgHR: avgHR,
            restingHR: restingHRData.value,
            maxHR: maxHeartRate,
            durationMinutes: durationMinutes,
            //trimp: trimp
        )
    }
    
    public func fetchHRRecovery(for workout: HKWorkout) async throws -> Int? {
        // Pobierz max HR podczas treningu
        guard let maxHRDuring = workout.statistics(for: HKQuantityType(.heartRate))?
            .maximumQuantity()?
            .doubleValue(for: .count().unitDivided(by: .minute()))
        else {
            print("⚠️ WorkoutMetricsManager: No max HR for workout")
            return nil
        }
        
        // Pobierz HR 1 minutę po treningu
        guard let hrAfter1Min = try await activityManager.fetchHeartRateAfterWorkout(
            workout: workout,
            afterSeconds: 60
        ) else {
            print("⚠️ WorkoutMetricsManager: No HR data after workout")
            return nil
        }
        
        return calculator.calculateHRRecovery(
            maxHRDuringWorkout: maxHRDuring,
            hrAfter1Minute: hrAfter1Min
        )
    }
    
    public func fetchIntensityFactor(for workout: HKWorkout, maxHeartRate: Double) async throws -> Double? {
        guard let avgHR = workout.statistics(for: HKQuantityType(.heartRate))?
            .averageQuantity()?
            .doubleValue(for: .count().unitDivided(by: .minute()))
        else {
            print("⚠️ WorkoutMetricsManager: No average HR for workout")
            return nil
        }
        
        return calculator.calculateIntensityFactor(
            avgHR: avgHR,
            maxHR: maxHeartRate
        )
    }
    
    public func fetchRecoveryDemand(for workout: HKWorkout, maxHeartRate: Double) async throws -> RecoveryDemand? {
        // Get hrTSS (required)
        guard let hrTSS = try await fetchHRTSS(for: workout, maxHeartRate: maxHeartRate) else {
            print("⚠️ WorkoutMetricsManager: No hrTSS for recovery demand")
            return nil
        }
        
        // Get HR Recovery (optional)
        let hrRecovery = try? await fetchHRRecovery(for: workout)
        
        // TODO: Get HRV ratio (morning HRV / 7-day average) when available
        let hrvRatio: Double? = nil
        
        // TODO: Get sleep hours from previous night when available
        let sleepHours: Double? = nil
        
        let hours = calculator.calculateRecoveryDemand(
            hrTSS: hrTSS,
            hrRecovery: hrRecovery,
            hrvRatio: hrvRatio,
            sleepHours: sleepHours
        )
        
        return RecoveryDemand(hours: hours)
    }
}
