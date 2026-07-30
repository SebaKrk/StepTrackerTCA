//
//  WorkoutHRSnapshot.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 28/06/2026.
//

import Foundation

/// Snapshot maksymalnego tętna dla pojedynczego workout'u — zapisany w momencie pierwszej
/// kalkulacji (lazy creation on first detail view open). **Freeze per-workout**: zmiana
/// formuły w Settings nie wpływa na historyczne workout'y które już mają snapshot.
///
/// **Loose coupling**: `formulaRawValue: String` (zamiast `HRFormulaType` enum) bo
/// SharedModels NIE depend'uje od HealthHub gdzie enum żyje. Konwersja `String <-> HRFormulaType`
/// po stronie HealthHub w `WorkoutHRSnapshotClient`.
public struct WorkoutHRSnapshot: Identifiable, Equatable, Codable, Sendable {

    /// Unique identifier — stable across updates, used for CloudKit sync.
    public let id: UUID

    /// Reference do HealthKit `HKWorkout.uuid` — primary lookup key (1:1 relationship).
    public let hkWorkoutId: UUID

    /// Frozen maxHR value liczone z `formulaRawValue` + `ageAtWorkout` + `biologicalSex`
    /// w momencie snapshot creation.
    public let maxHR: Double

    /// `HRFormulaType.rawValue` (np. "tanaka", "nes", "gulati", "fairbarn", "classic").
    /// String loose coupling — SharedModels nie wie nic o HRFormulaType enum.
    public let formulaRawValue: String

    /// Wiek user'a w momencie snapshot creation (lat).
    public let ageAtWorkout: Int

    /// Biological sex z HealthKit w momencie snapshot creation.
    public let biologicalSex: BiologicalSex

    public init(
        id: UUID,
        hkWorkoutId: UUID,
        maxHR: Double,
        formulaRawValue: String,
        ageAtWorkout: Int,
        biologicalSex: BiologicalSex
    ) {
        self.id = id
        self.hkWorkoutId = hkWorkoutId
        self.maxHR = maxHR
        self.formulaRawValue = formulaRawValue
        self.ageAtWorkout = ageAtWorkout
        self.biologicalSex = biologicalSex
    }
}
