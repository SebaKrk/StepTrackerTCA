//
//  WorkoutSummaryLoader.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 26/06/2026.
//

import Foundation
import HealthKit
import SharedModels

/// Loads workout data from a finalized `HKWorkout` for the manual-entry path
/// (`ActivityDetailsFeature → SummaryFeature` z History).
///
/// Happy path: `SessionClient.getWorkoutSummary()` ściąga workout z `trainingManager` lub
/// świeży HK fetch i buduje `WorkoutSummary` "na żywo". Manual entry **nie ma** aktywnej sesji —
/// user otwiera trening z History po fakcie. Te helper'y rekonstruują `WorkoutSummary` + `hrBuffer`
/// z HealthKit dla danego workout'u.
public enum WorkoutSummaryLoader {

    // MARK: - Public

    /// Buduje `WorkoutSummary` + HR buffer **jednym** HK query. Zwraca tuple bo callsite
    /// (ActivityDetailsFeature) potrzebuje obu naraz. Single-query versja eliminuje 2× XPC
    /// round-trip do `healthd` (poprzednio: osobny statistics query + samples query).
    ///
    /// `averageHR` liczone lokalnie z `samples` (count + sum) — bez osobnego HKStatisticsQuery.
    /// `activeEnergy` z `HKWorkoutStatistics` (już zawarte w HKWorkout, bez XPC).
    public static func loadComplete(
        for hkWorkout: HKWorkout,
        healthStore: HKHealthStore
    ) async throws -> (summary: WorkoutSummary, hrBuffer: [(date: Date, bpm: Double)]) {
        let hrBuffer = try await heartRateSamples(for: hkWorkout, healthStore: healthStore)
        let averageHR = hrBuffer.isEmpty
            ? 0
            : hrBuffer.map(\.bpm).reduce(0, +) / Double(hrBuffer.count)
        let activeEnergy = hkWorkout
            .statistics(for: HKQuantityType(.activeEnergyBurned))?
            .sumQuantity()?
            .doubleValue(for: .kilocalorie()) ?? 0
        let metrics = WorkoutMetrics(
            averageHeartRate: averageHR,
            heartRate: 0,
            activeEnergy: activeEnergy
        )
        let summary = WorkoutSummary(workout: hkWorkout, metrics: metrics)
        return (summary, hrBuffer)
    }

    /// Pobiera wszystkie HR samples (`HKQuantityType.heartRate`) z zakresu workout'u —
    /// `hkWorkout.startDate ... endDate`. Public, bo używane też przez inne miejsca które potrzebują
    /// tylko samples (bez summary).
    public static func heartRateSamples(
        for hkWorkout: HKWorkout,
        healthStore: HKHealthStore
    ) async throws -> [(date: Date, bpm: Double)] {
        let predicate = HKQuery.predicateForSamples(
            withStart: hkWorkout.startDate,
            end: hkWorkout.endDate
        )
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: HKQuantityType(.heartRate), predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .forward)]
        )
        let samples = try await descriptor.result(for: healthStore)
        let bpmUnit = HKUnit.count().unitDivided(by: .minute())
        return samples.map { sample in
            (date: sample.startDate, bpm: sample.quantity.doubleValue(for: bpmUnit))
        }
    }
}
