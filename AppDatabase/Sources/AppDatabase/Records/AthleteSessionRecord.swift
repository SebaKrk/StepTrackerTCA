//
//  AthleteSessionRecord.swift
//  AppDatabase
//
//  Created by Sebastian Ściuba on 17/06/2026.
//

import Foundation
import SharedModels
import SQLiteData

// MARK: - Record

/// Persisted record jednego sportowca w jednej klasie. FK do `ClassSessionRecord`.
///
/// **Storage strategy**: scalar metadata → TEXT/INTEGER, time-series + aggregates → BLOB:
/// - `hrSamplesData` — JSON-encoded `[HRSample]` (1Hz @ 60min ≈ 3600 entries ≈ 200KB)
/// - `aggregatedStatsData` — JSON-encoded `ClassAnalytics` (avg, peak, calories, zones)
///
/// **BLOB approach** vs osobna tabela `hrSampleRecords`: 36000 rows per klasa
/// (10 athletes × 60min × 1Hz) zalałoby table'a. BLOB = jeden row per athlete-session,
/// JSON deserialize on-demand do charts.
///
/// **Lifecycle**: `leftAt == nil` → athlete jeszcze podłączony (mid-class). Crash
/// recovery analogiczne do `ClassSessionRecord.endedAt`.
@Table
public struct AthleteSessionRecord: Identifiable, CloudKitSyncable {

    // MARK: - Properties

    public var id: UUID

    /// FK do `ClassSessionRecord.id`. Jeden session ma N athletes (max = `GymClassRecord.maxParticipants`).
    public var classSessionId: UUID

    /// `HRSamplePayload.deviceID` — stabilny per-install identyfikator peer'a.
    /// Reconnect detection: ten sam deviceID w dwóch session'ach = "Seba wczoraj + dziś".
    public var deviceID: UUID

    /// Display nick z peer'a (`HRSamplePayload.nick`). Może być empty / duplikat między athletes
    /// (różne deviceID, ten sam nick — np. dwóch "Seba").
    public var nick: String

    /// Snapshot `maxHR` z momentu pierwszej próbki (UserProfile peer'a). Używany dla
    /// `%HR` calculation w charts gdy retrospekcyjnie patrzymy na past sessions.
    public var maxHR: Int

    /// JSON-encoded `[HRSample]` — chronological, sortowane po `timestamp` ASC.
    /// Format: array of `{ timestamp, bpm, activeEnergy }`.
    public var hrSamplesData: Data

    /// JSON-encoded `ClassAnalytics` snapshot — computed na `peerDisconnected` /
    /// session end. Nie re-compute po insert (raw samples są w `hrSamplesData`
    /// dla future recompute jeśli zmieni się maxHR).
    public var aggregatedStatsData: Data

    /// Pierwsze odebranie próbki HR z tego peer'a w tym session'ie.
    public var joinedAt: Date

    /// Ostatnie odebranie próbki lub explicit `peerDisconnected`. `nil` = jeszcze
    /// podłączony (live mid-class).
    public var leftAt: Date?

    // MARK: - CloudKitSyncable

    public var createdAt: Date
    public var updatedAt: Date
    public var ckRecordData: Data?

    // MARK: - Init

    public init(
        id: UUID,
        classSessionId: UUID,
        deviceID: UUID,
        nick: String,
        maxHR: Int,
        hrSamplesData: Data,
        aggregatedStatsData: Data,
        joinedAt: Date,
        leftAt: Date?,
        createdAt: Date,
        updatedAt: Date,
        ckRecordData: Data? = nil
    ) {
        self.id = id
        self.classSessionId = classSessionId
        self.deviceID = deviceID
        self.nick = nick
        self.maxHR = maxHR
        self.hrSamplesData = hrSamplesData
        self.aggregatedStatsData = aggregatedStatsData
        self.joinedAt = joinedAt
        self.leftAt = leftAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.ckRecordData = ckRecordData
    }
}
