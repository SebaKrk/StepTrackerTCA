//
//  PREntryRecord.swift
//  AppDatabase
//
//  Created by Sebastian Ściuba on 01/09/2026.
//

import Foundation
import SharedModels
import SQLiteData

// MARK: - Record

/// SQLite record for a PR Board result entry (`PREntry`).
///
/// Loose relation to the static PR catalog via `movementId` (no FK — catalog
/// lives in code). Duplicates per movement+day are allowed by design; ties are
/// resolved by `PRResolver` (date, then createdAt). No denormalized "best"
/// anywhere — the current PR is always derived from history (FR-007).
///
/// Storage strategy: flat scalar columns (no BLOB) — the score enum is exploded
/// into `scoreType` + one populated value group, equipment is a comma-joined
/// rawValue list.
@Table
public struct PREntryRecord: Identifiable, CloudKitSyncable, Sendable {

    // MARK: - Properties

    /// Unique identifier — stable across updates, used for CloudKit sync.
    public var id: UUID

    /// Reference to `PRMovement.id` from the static catalog (kebab-case, e.g. "back-squat").
    public var movementId: String

    /// User-chosen day of the result (form-capped at "today").
    public var date: Date

    /// `PRScoreType` rawValue — selects which value group below is populated.
    public var scoreType: String

    /// Weight score value in kilograms (`scoreType == weight`).
    public var weightKg: Double?

    /// Time score value in whole seconds, lower wins (`scoreType == time`).
    public var timeSeconds: Int?

    /// Completed rounds for AMRAP, or the rep count for rep-based scores
    /// (`reps` reuses this single INTEGER slot).
    public var rounds: Int?

    /// Extra reps beyond the last full round (`scoreType == amrap` only).
    public var extraReps: Int?

    /// Rx (true) / scaled (false); nil when the movement has no Rx standard.
    public var isRx: Bool?

    /// Comma-joined `PREquipment` rawValues, sorted for stable storage ("" = none).
    public var equipment: String

    /// Rate of perceived exertion (6.0–10.0 in 0.5 steps); nil = not reported.
    public var rpe: Double?

    /// Free-form user note.
    public var note: String?

    /// Body-weight snapshot in kilograms taken at save time — nil when
    /// HealthKit had no reading (never blocks the save).
    public var bodyWeightKg: Double?

    /// `PRContext` rawValue — circumstances of the attempt (fresh/inWod/competition).
    public var context: String

    // MARK: - CloudKitSyncable

    public var createdAt: Date
    public var updatedAt: Date
    public var ckRecordData: Data?

    // MARK: - Init

    public init(
        id: UUID,
        movementId: String,
        date: Date,
        scoreType: String,
        weightKg: Double? = nil,
        timeSeconds: Int? = nil,
        rounds: Int? = nil,
        extraReps: Int? = nil,
        isRx: Bool? = nil,
        equipment: String = "",
        rpe: Double? = nil,
        note: String? = nil,
        bodyWeightKg: Double? = nil,
        context: String,
        createdAt: Date,
        updatedAt: Date,
        ckRecordData: Data? = nil
    ) {
        self.id = id
        self.movementId = movementId
        self.date = date
        self.scoreType = scoreType
        self.weightKg = weightKg
        self.timeSeconds = timeSeconds
        self.rounds = rounds
        self.extraReps = extraReps
        self.isRx = isRx
        self.equipment = equipment
        self.rpe = rpe
        self.note = note
        self.bodyWeightKg = bodyWeightKg
        self.context = context
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.ckRecordData = ckRecordData
    }
}

// MARK: - Mapping

extension PREntryRecord {

    public init(from entry: PREntry, updatedAt: Date) {
        var weightKg: Double?
        var timeSeconds: Int?
        var rounds: Int?
        var extraReps: Int?
        switch entry.score {
        case let .weight(kilograms):
            weightKg = kilograms
        case let .time(seconds):
            timeSeconds = seconds
        case let .reps(count):
            // Rep-count scores reuse the `rounds` column (single INTEGER slot).
            rounds = count
        case let .amrap(roundsValue, extraRepsValue):
            rounds = roundsValue
            extraReps = extraRepsValue
        }

        self.init(
            id: entry.id,
            movementId: entry.movementId,
            date: entry.date,
            scoreType: entry.score.scoreType.rawValue,
            weightKg: weightKg,
            timeSeconds: timeSeconds,
            rounds: rounds,
            extraReps: extraReps,
            isRx: entry.isRx,
            equipment: entry.equipment.map(\.rawValue).sorted().joined(separator: ","),
            rpe: entry.rpe,
            note: entry.note,
            bodyWeightKg: entry.bodyWeightKg,
            context: entry.context.rawValue,
            createdAt: entry.createdAt,
            updatedAt: updatedAt
        )
    }

    /// nil when the stored scoreType/value group is unreadable (defensive, like `?? .rx` in ExerciseLogRecord).
    public func toDomain() -> PREntry? {
        guard let type = PRScoreType(rawValue: scoreType) else { return nil }
        let score: PRScoreValue
        switch type {
        case .weight:
            guard let weightKg else { return nil }
            score = .weight(kilograms: weightKg)
        case .time:
            guard let timeSeconds else { return nil }
            score = .time(seconds: timeSeconds)
        case .reps:
            guard let rounds else { return nil }
            score = .reps(count: rounds)
        case .amrap:
            guard let rounds, let extraReps else { return nil }
            score = .amrap(rounds: rounds, extraReps: extraReps)
        }
        let equipmentSet = Set(
            equipment.split(separator: ",").compactMap { PREquipment(rawValue: String($0)) }
        )
        return PREntry(
            id: id,
            movementId: movementId,
            date: date,
            createdAt: createdAt,
            score: score,
            isRx: isRx,
            equipment: equipmentSet,
            rpe: rpe,
            note: note,
            bodyWeightKg: bodyWeightKg,
            context: PRContext(rawValue: context) ?? .fresh
        )
    }
}
