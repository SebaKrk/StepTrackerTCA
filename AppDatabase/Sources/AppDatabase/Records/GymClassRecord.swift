//
//  GymClassRecord.swift
//  AppDatabase
//
//  Created by Sebastian Ściuba on 17/06/2026.
//

import Foundation
import SharedModels
import SQLiteData

// MARK: - Record

/// Persisted schedule template dla klasy treningowej w GymRoom (iPad app).
///
/// **Template pattern**: re-usable entry (np. "Morning CrossFit" co wtorek).
/// Każde uruchomienie tworzy osobny `ClassSessionRecord` z FK do tego template'a.
///
/// **Storage strategy**: scalar fields → flat TEXT/INTEGER columns. Brak nested
/// structures — schedule template to czyste metadata.
///
/// **CloudKit**: `ckRecordData == nil` do IPAD-0097 aktywuje `SyncEngine`.
@Table
public struct GymClassRecord: Identifiable, CloudKitSyncable {

    // MARK: - Properties

    /// Unique identifier — stable across updates, foreign key dla ClassSessionRecord.
    public var id: UUID

    /// User-defined name klasy (np. "Morning CrossFit"). Mandatory.
    public var name: String

    /// Sala / lokalizacja (np. "Sala 1"). Mandatory.
    public var location: String

    /// Planowany start. `nil` = klasa bez ustalonej daty (sekcja "Without date" w UI).
    public var scheduledAt: Date?

    /// Max BLE concurrent peers. Set'owany w ClassCreation z `BLECapacityClient`
    /// recommended dla device'a (8/12/16).
    public var maxParticipants: Int

    // MARK: - CloudKitSyncable

    public var createdAt: Date
    public var updatedAt: Date
    public var ckRecordData: Data?

    // MARK: - Init

    public init(
        id: UUID,
        name: String,
        location: String,
        scheduledAt: Date?,
        maxParticipants: Int,
        createdAt: Date,
        updatedAt: Date,
        ckRecordData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.location = location
        self.scheduledAt = scheduledAt
        self.maxParticipants = maxParticipants
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.ckRecordData = ckRecordData
    }
}
