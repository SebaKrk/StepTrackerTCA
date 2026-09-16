//
//  RunningDynamicsLoader.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 07/08/2026.
//

import Foundation
import HealthKit

/// Running-dynamics metrics Apple Watch records automatically for runs
/// (watchOS 9+): power, stride length, vertical oscillation, ground contact
/// time — plus cadence derived from steps. Every field is optional: a run
/// recorded without a Watch (BLE strap, another app) simply has no samples.
public struct RunningDynamics: Sendable {

    /// Average running power, in watts.
    public let averagePower: Double?

    /// Average cadence, in steps per minute (workout steps over duration).
    public let cadence: Double?

    /// Average stride length, in meters.
    public let strideLength: Double?

    /// Average vertical oscillation, in centimeters.
    public let verticalOscillation: Double?

    /// Average ground contact time, in milliseconds.
    public let groundContactTime: Double?

    /// `true` when no metric has data — the UI hides the whole section.
    public var isEmpty: Bool {
        averagePower == nil
            && cadence == nil
            && strideLength == nil
            && verticalOscillation == nil
            && groundContactTime == nil
    }
}

/// Loads running dynamics for a finished workout straight from HealthKit
/// statistics ("derive, don't persist" — works retroactively for any run
/// recorded with a Watch, regardless of which app saved it).
public enum RunningDynamicsLoader {

    public static func load(
        for workout: HKWorkout,
        healthStore: HKHealthStore
    ) async -> RunningDynamics {
        async let power = averageQuantity(
            .runningPower, for: workout, healthStore: healthStore, unit: .watt()
        )
        async let stride = averageQuantity(
            .runningStrideLength, for: workout, healthStore: healthStore, unit: .meter()
        )
        async let oscillation = averageQuantity(
            .runningVerticalOscillation, for: workout, healthStore: healthStore,
            unit: .meterUnit(with: .centi)
        )
        async let groundContact = averageQuantity(
            .runningGroundContactTime, for: workout, healthStore: healthStore,
            unit: .secondUnit(with: .milli)
        )
        async let steps = sumQuantity(
            .stepCount, for: workout, healthStore: healthStore, unit: .count()
        )

        let stepsValue = await steps
        let cadence: Double?
        if let stepsValue, workout.duration > 0 {
            cadence = stepsValue / (workout.duration / 60)
        } else {
            cadence = nil
        }

        return await RunningDynamics(
            averagePower: power,
            cadence: cadence,
            strideLength: stride,
            verticalOscillation: oscillation,
            groundContactTime: groundContact
        )
    }

    // MARK: - Private

    private static func averageQuantity(
        _ identifier: HKQuantityTypeIdentifier,
        for workout: HKWorkout,
        healthStore: HKHealthStore,
        unit: HKUnit
    ) async -> Double? {
        await statistics(identifier, options: .discreteAverage, for: workout, healthStore: healthStore)?
            .averageQuantity()?
            .doubleValue(for: unit)
    }

    private static func sumQuantity(
        _ identifier: HKQuantityTypeIdentifier,
        for workout: HKWorkout,
        healthStore: HKHealthStore,
        unit: HKUnit
    ) async -> Double? {
        await statistics(identifier, options: .cumulativeSum, for: workout, healthStore: healthStore)?
            .sumQuantity()?
            .doubleValue(for: unit)
    }

    /// One-shot `HKStatisticsQuery` over the workout's time window. Errors and
    /// missing data both come back as `nil` — a run without a given metric is
    /// a normal case, not a failure.
    private static func statistics(
        _ identifier: HKQuantityTypeIdentifier,
        options: HKStatisticsOptions,
        for workout: HKWorkout,
        healthStore: HKHealthStore
    ) async -> HKStatistics? {
        let predicate = HKQuery.predicateForSamples(
            withStart: workout.startDate,
            end: workout.endDate,
            options: .strictStartDate
        )
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: HKQuantityType(identifier),
                quantitySamplePredicate: predicate,
                options: options
            ) { _, statistics, _ in
                continuation.resume(returning: statistics)
            }
            healthStore.execute(query)
        }
    }
}
