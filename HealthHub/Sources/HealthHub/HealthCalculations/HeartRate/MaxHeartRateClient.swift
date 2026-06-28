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
        @Dependency(\.workoutHRSnapshotClient) var snapshotClient
        @Dependency(\.calendar) var calendar
        @Dependency(\.uuid) var uuid

        // User's choice persisted via `@Shared(.appStorage)` w `HRFormulaSettingsFeature`.
        // Default `.tanaka` — modern statistical standard (Apple Health baseline).
        //
        // `@Shared` declared **wewnątrz** każdej closure — Swift 6 strict concurrency wymóg.
        //
        // ✅ **Snapshot freeze (IOS-00097-F)**: `forWorkout` najpierw sprawdza istniejący
        //    snapshot per HKWorkout. Jeśli istnieje → cached value (formuła z momentu pierwszej
        //    kalkulacji). Jeśli brak → liczy z current `@Shared` formula + zapisuje snapshot.
        //    Konsekwencja: zmiana formuły w Settings NIE zmienia historycznych workout'ów.
        return MaxHeartRateClient(
            forWorkout: { workout in
                // Step 1: try cached snapshot (per-workout freeze).
                if let snapshot = try? await snapshotClient.fetchByHKWorkoutId(workout.uuid) {
                    return snapshot.maxHR
                }

                // Step 2: brak snapshot'u — compute z current formula + persist.
                @Shared(.appStorage("hrFormula")) var formula: HRFormulaType = .tanaka
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
                let maxHR = Double(heartRateCalculator.calculateMaxHeartRate(
                    age: age,
                    biologicalSex: sex,
                    formula: formula
                ))

                // Step 3: save snapshot — następne wywołania dla tego workout'u
                // zwrócą cached value, niezależnie od późniejszej zmiany formuły.
                let snapshot = WorkoutHRSnapshot(
                    id: uuid(),
                    hkWorkoutId: workout.uuid,
                    maxHR: maxHR,
                    formulaRawValue: formula.rawValue,
                    ageAtWorkout: age,
                    biologicalSex: sex
                )
                try? await snapshotClient.save(snapshot)
                return maxHR
            },
            fromAge: { age, sex in
                // Settings preview — używa current formula bez snapshot'u (nie dotyczy workout'u).
                @Shared(.appStorage("hrFormula")) var formula: HRFormulaType = .tanaka
                return Double(heartRateCalculator.calculateMaxHeartRate(
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
