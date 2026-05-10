//
//  MaxHeartRateClient.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 08/05/2026.
//

import ComposableArchitecture
import Foundation
import HealthKit
import SharedModels

// MARK: - Client

/// Single source of truth for user's max heart rate calculations.
///
/// Delegates the formula to `HeartRateCalculator` (currently Nes 2013) so settings,
/// workout sessions, and historical analytics all show consistent values.
///
/// - `forWorkout`: async resolver — fetches HealthKit `birthDate` + biological sex,
///   computes `ageAtWorkout` from workout's start date. Time-stable: the same workout
///   viewed today and 10 years from now yields identical zones.
/// - `fromAge`: sync calculation when age + sex are already known (e.g., from a settings
///   form where the user can preview values before saving).
///
/// Falls back to `190.0` if HealthKit data is unavailable.
public struct MaxHeartRateClient: Sendable {

    /// Async: resolves max HR at the start time of the given workout (time-stable).
    public var forWorkout: @Sendable (HKWorkout) async -> Double

    /// Sync: computes max HR from explicit age + biological sex.
    public var fromAge: @Sendable (Int, BiologicalSex) -> Double
}

// MARK: - DependencyKey

public enum MaxHeartRateClientKey: DependencyKey {

    public static let liveValue: MaxHeartRateClient = {
        @Dependency(\.personalDataManager) var personalDataManager
        @Dependency(\.heartRateCalculator) var heartRateCalculator
        @Dependency(\.calendar) var calendar

        // Single point of truth for which formula the whole app uses.
        // Change this constant to switch every consumer (settings, workouts, analytics).
        let formula: HRFormulaType = .nes

        return MaxHeartRateClient(
            forWorkout: { workout in
                guard let birthDate = try? await personalDataManager.getBirthDate() else {
                    return 190
                }
                let years = calendar.dateComponents(
                    [.year],
                    from: birthDate,
                    to: workout.startDate
                ).year ?? 30
                let age = max(years, 0)
                let sex = (try? await personalDataManager.getBiologicalSex()) ?? .unknown
                return Double(heartRateCalculator.calculateMaxHeartRate(
                    age: age,
                    biologicalSex: sex,
                    formula: formula
                ))
            },
            fromAge: { age, sex in
                Double(heartRateCalculator.calculateMaxHeartRate(
                    age: age,
                    biologicalSex: sex,
                    formula: formula
                ))
            }
        )
    }()

    public static var testValue: MaxHeartRateClient {
        MaxHeartRateClient(
            forWorkout: unimplemented("MaxHeartRateClient.forWorkout", placeholder: 190),
            fromAge: unimplemented("MaxHeartRateClient.fromAge", placeholder: 190)
        )
    }
}

// MARK: - DependencyValues

public extension DependencyValues {
    var maxHeartRateClient: MaxHeartRateClient {
        get { self[MaxHeartRateClientKey.self] }
        set { self[MaxHeartRateClientKey.self] = newValue }
    }
}
