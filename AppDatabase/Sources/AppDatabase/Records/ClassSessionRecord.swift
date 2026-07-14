//
//  ClassSessionRecord.swift
//  AppDatabase
//
//  Created by Sebastian Ściuba on 17/06/2026.
//

import Foundation
import SharedModels
import SQLiteData

// MARK: - Record

/// Persisted instance uruchomienia klasy treningowej — jedno wystąpienie w czasie.
///
/// **Relationship**: FK do `GymClassRecord` (template). Jeden template może mieć
/// N session'ów (re-runs — "Morning CrossFit" wczoraj, dziś, jutro = 3 sessions
/// + 1 template). SQLite **bez foreign key constraints** (limit `SQLiteData`) —
/// integrytet pilnowany w domain layer.
///
/// **Snapshot strategy**: `className` + `location` są snapshot'em z template'a
/// w momencie startu. Powód: gdy trener zedytuje template po wybiegnięciu klasy
/// (np. rename "Morning CrossFit" → "Strength Wednesday"), history nie powinno
/// retro-aktywnie zmieniać past sessions.
///
/// **Lifecycle**: `endedAt == nil` → ongoing (live). Crash recovery na app launch:
/// `WHERE endedAt IS NULL → set endedAt = updatedAt` (defensive cleanup).
@Table
public struct ClassSessionRecord: Identifiable, CloudKitSyncable, Sendable {

    // MARK: - Properties

    /// Unique identifier — stable, używany jako FK w `AthleteSessionRecord`.
    public var id: UUID

    /// FK do `GymClassRecord.id`. Nie cascading delete — usuwając template
    /// past sessions zostają (history retention).
    public var gymClassId: UUID

    /// Snapshot nazwy klasy z momentu startu (immune na późniejsze rename template'a).
    public var className: String

    /// Snapshot location z momentu startu.
    public var location: String

    /// Czas faktycznego Start class. UTC, source of truth dla history sorting.
    public var startedAt: Date

    /// Czas End class. `nil` = ongoing (live, jeszcze nie zakończona).
    public var endedAt: Date?

    // MARK: - CloudKitSyncable

    public var createdAt: Date
    public var updatedAt: Date
    public var ckRecordData: Data?

    // MARK: - Init

    public init(
        id: UUID,
        gymClassId: UUID,
        className: String,
        location: String,
        startedAt: Date,
        endedAt: Date?,
        createdAt: Date,
        updatedAt: Date,
        ckRecordData: Data? = nil
    ) {
        self.id = id
        self.gymClassId = gymClassId
        self.className = className
        self.location = location
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.ckRecordData = ckRecordData
    }
}
