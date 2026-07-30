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

    /// Planowany start. Dla zajęć cyklicznych (`isRecurring`) to data BAZOWA
    /// pierwszego wystąpienia — kolejne terminy liczone są co tydzień od niej.
    /// `nil` = klasa bez ustalonej daty (sekcja "Without date" w UI).
    public var scheduledAt: Date?

    /// Max BLE concurrent peers. Set'owany w ClassCreation z `BLECapacityClient`
    /// recommended dla device'a (8/12/16).
    public var maxParticipants: Int

    /// Geocoded address coordinates from the MapKit address picker. `nil` when the
    /// location was typed freehand or predates the address feature — reserved for
    /// the map shown in the athlete recap (future).
    public var latitude: Double?
    public var longitude: Double?

    /// Weekly recurrence flag. `true` = repeats every week on `scheduledAt`'s
    /// weekday+time; the displayed date rolls forward (next occurrence ≥ now)
    /// without generating separate records.
    public var isRecurring: Bool

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
        latitude: Double? = nil,
        longitude: Double? = nil,
        isRecurring: Bool = false,
        createdAt: Date,
        updatedAt: Date,
        ckRecordData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.location = location
        self.scheduledAt = scheduledAt
        self.maxParticipants = maxParticipants
        self.latitude = latitude
        self.longitude = longitude
        self.isRecurring = isRecurring
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.ckRecordData = ckRecordData
    }
}
