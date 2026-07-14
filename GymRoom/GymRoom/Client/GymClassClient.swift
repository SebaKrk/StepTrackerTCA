//
//  GymClassClient.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 17/06/2026.
//

import AppDatabase
import ComposableArchitecture
import Foundation
import SharedModels
import SQLiteData

/// The Composable Architecture (TCA) dependency boundary nad SQLiteData queries
/// dla GymRoom domain. Trzy obszary:
/// - **Templates**: CRUD operacje na `GymClassRecord` (schedule template).
/// - **Sessions**: lifecycle `ClassSessionRecord` (Start → live → End).
/// - **Athletes**: lifecycle `AthleteSessionRecord` (peer connect → batch HR → disconnect).
///
/// **Pattern**: ten sam co `TrainingSessionClient` / `WorkoutPlanScoreClient` —
/// `struct: Sendable` z closure properties (bez `@DependencyClient` macro),
/// `private enum XxxClientKey: DependencyKey` zamiast extension.
///
/// **Threading**: closure'y `async throws` — wewnątrz `database.write { }` SQLite jest
/// serialized (single-writer lock), race conditions niemożliwe między batch'ami.
struct GymClassClient: Sendable {

    // MARK: - Templates (GymClassRecord)

    var fetchAllTemplates: @Sendable () async throws -> [GymClass]
    var saveTemplate: @Sendable (_ gymClass: GymClass) async throws -> Void
    var deleteTemplate: @Sendable (_ id: UUID) async throws -> Void

    // MARK: - Sessions (ClassSessionRecord)

    /// Wszystkie session records reverse-chrono (newest first) — dla History tab.
    var fetchAllSessions: @Sendable () async throws -> [ClassSessionRecord]

    /// Returns: `sessionId` (UUID) do trzymania w State pod batch HR persistence.
    var startSession: @Sendable (_ gymClassId: UUID, _ className: String, _ location: String) async throws -> UUID

    /// Set `endedAt` na session'ie. Plus finalize wszystkich athletes z `leftAt == nil`
    /// (defensive: trener wyłączył klasę zanim peer się rozłączył) — compute analytics
    /// dla każdego z nich, set `leftAt = endedAt`.
    var endSession: @Sendable (_ sessionId: UUID, _ endedAt: Date) async throws -> Void

    /// Cascade delete pojedynczej sesji z History — kasuje session record + wszystkie
    /// athleteSessionRecords FK do niej. NIE rusza template'a (gymClassRecord zostaje).
    /// W odróżnieniu od `deleteTemplate` (kasuje template + WSZYSTKIE jego sesje), ten
    /// usuwa **jeden konkretny historical entry** wraz z HR data sportowców.
    var deleteSession: @Sendable (_ sessionId: UUID) async throws -> Void

    // MARK: - Athletes (AthleteSessionRecord)

    /// Wszyscy athletes podłączeni do danej sesji (FK match) — dla detail view w History.
    /// Returns raw records z BLOB-ami (`hrSamplesData`, `aggregatedStatsData`); decode
    /// w Reducer wrapping na `AthleteSummary` domain model.
    var fetchAthletesForSession: @Sendable (_ classSessionId: UUID) async throws -> [AthleteSessionRecord]

    /// Returns: `athleteId` (UUID) do batch HR persistence keyed po nim.
    var addAthlete: @Sendable (_ classSessionId: UUID, _ deviceID: UUID, _ nick: String, _ maxHR: Int) async throws -> UUID

    /// Sprawdza czy w sesji istnieje już `AthleteSessionRecord` z tym `deviceID`
    /// (per-install peer identifier). Używane w `peerConnected` żeby zdecydować:
    /// **resume** (existing record) vs **create** (new). Recovery dla scenariusza
    /// gdy peer wybiega poza BLE range > grace period — wraca jako fresh `.connected`
    /// event ale to ten sam athlete.
    ///
    /// Returns: `athleteId` jeśli istnieje, nil jeśli ten deviceID nigdy nie był w tej sesji.
    var findAthlete: @Sendable (_ classSessionId: UUID, _ deviceID: UUID) async throws -> UUID?

    /// Wznawia athletę po reconnect — clear `leftAt = nil`. Zachowuje istniejące
    /// `hrSamplesData` BLOB; następne `appendHRSamples` doda nowe samples do
    /// istniejących. Total kcal liczone z delta cumulative `activeEnergy` (Watch
    /// nie resetuje liczników przy BLE disconnect), więc final kcal poprawne
    /// niezależnie od gap'ów w BLE.
    var resumeAthlete: @Sendable (_ athleteId: UUID) async throws -> Void

    /// Append `[HRSample]` do BLOB `hrSamplesData`. Read existing → decode →
    /// append → encode → upsert. Wywoływane co 30s przez timer effect.
    var appendHRSamples: @Sendable (_ athleteId: UUID, _ samples: [HRSample]) async throws -> Void

    /// Finalize athlete na `peerDisconnected`. Idempotent — drugi call (np. po `endSession`
    /// już sfinalizował) jest no-op.
    var endAthlete: @Sendable (_ athleteId: UUID, _ leftAt: Date) async throws -> Void
}

// MARK: - DependencyValues

extension DependencyValues {
    var gymClassClient: GymClassClient {
        get { self[GymClassClientKey.self] }
        set { self[GymClassClientKey.self] = newValue }
    }
}

// MARK: - DependencyKey

private enum GymClassClientKey: DependencyKey {

    static let liveValue: GymClassClient = {
        @Dependency(\.defaultDatabase) var database

        return GymClassClient(
            fetchAllTemplates: {
                try await database.read { db in
                    try GymClassRecord
                        .order { $0.createdAt.desc() }
                        .fetchAll(db)
                        .map { $0.toDomain() }
                }
            },

            saveTemplate: { gymClass in
                @Dependency(\.date.now) var now
                try await database.write { db in
                    let record = GymClassRecord(domain: gymClass, updatedAt: now)
                    let draft = GymClassRecord.Draft(
                        id: record.id,
                        name: record.name,
                        location: record.location,
                        scheduledAt: record.scheduledAt,
                        maxParticipants: record.maxParticipants,
                        createdAt: record.createdAt,
                        updatedAt: record.updatedAt
                    )
                    try GymClassRecord.upsert { draft }.execute(db)
                }
            },

            deleteTemplate: { id in
                /// Cascade delete w jednej transakcji: usunięcie template'a kasuje też
                /// wszystkie powiązane session records + athlete records. Bez tego —
                /// orphan'ed past sessions zostaną w History tab bez działającego back-link.
                /// Wymóg z user feedback dla wersji 0.1: "usuń wszystko z athlete data".
                try await database.write { db in
                    /// 1. Find wszystkie classSessionRecords dla tego template'a.
                    let sessions = try ClassSessionRecord
                        .where { $0.gymClassId.eq(id) }
                        .fetchAll(db)
                    let sessionIds = sessions.map { $0.id }

                    /// 2. Delete wszystkie athleteSessionRecords FK do tych sessions.
                    if !sessionIds.isEmpty {
                        try AthleteSessionRecord
                            .where { $0.classSessionId.in(sessionIds) }
                            .delete()
                            .execute(db)
                    }

                    /// 3. Delete wszystkie classSessionRecords dla template'a.
                    try ClassSessionRecord
                        .where { $0.gymClassId.eq(id) }
                        .delete()
                        .execute(db)

                    /// 4. Finally delete sam template.
                    try GymClassRecord
                        .find(id)
                        .delete()
                        .execute(db)
                }
            },

            fetchAllSessions: {
                try await database.read { db in
                    try ClassSessionRecord
                        .order { $0.startedAt.desc() }
                        .fetchAll(db)
                }
            },

            startSession: { gymClassId, className, location in
                @Dependency(\.date.now) var now
                let id = UUID()
                try await database.write { db in
                    let draft = ClassSessionRecord.Draft(
                        id: id,
                        gymClassId: gymClassId,
                        className: className,
                        location: location,
                        startedAt: now,
                        endedAt: nil,
                        createdAt: now,
                        updatedAt: now
                    )
                    try ClassSessionRecord.upsert { draft }.execute(db)
                }
                return id
            },

            endSession: { sessionId, endedAt in
                @Dependency(\.date.now) var now
                let encoder = JSONEncoder()
                let decoder = JSONDecoder()
                try await database.write { db in
                    /// 1. Set endedAt na session'ie (read existing → build draft z modifications).
                    let existingSession = try ClassSessionRecord
                        .where { $0.id.eq(sessionId) }
                        .fetchOne(db)
                    guard let existing = existingSession else { return }

                    let sessionDraft = ClassSessionRecord.Draft(
                        id: existing.id,
                        gymClassId: existing.gymClassId,
                        className: existing.className,
                        location: existing.location,
                        startedAt: existing.startedAt,
                        endedAt: endedAt,
                        createdAt: existing.createdAt,
                        updatedAt: now
                    )
                    try ClassSessionRecord.upsert { sessionDraft }.execute(db)

                    /// 2. Finalize wszystkich ongoing athletes (leftAt == nil).
                    /// Compute analytics z BLOB samples + set leftAt = endedAt klasy.
                    let athletes = try AthleteSessionRecord
                        .where { $0.classSessionId.eq(sessionId) }
                        .fetchAll(db)

                    for athlete in athletes where athlete.leftAt == nil {
                        let samples = (try? decoder.decode([HRSample].self, from: athlete.hrSamplesData)) ?? []
                        let duration = endedAt.timeIntervalSince(athlete.joinedAt)
                        let analytics = ClassAnalytics.compute(
                            samples: samples,
                            maxHR: athlete.maxHR,
                            duration: duration
                        )
                        let analyticsData = try encoder.encode(analytics)

                        let athleteDraft = AthleteSessionRecord.Draft(
                            id: athlete.id,
                            classSessionId: athlete.classSessionId,
                            deviceID: athlete.deviceID,
                            nick: athlete.nick,
                            maxHR: athlete.maxHR,
                            hrSamplesData: athlete.hrSamplesData,
                            aggregatedStatsData: analyticsData,
                            joinedAt: athlete.joinedAt,
                            leftAt: endedAt,
                            createdAt: athlete.createdAt,
                            updatedAt: now
                        )
                        try AthleteSessionRecord.upsert { athleteDraft }.execute(db)
                    }
                }
            },

            deleteSession: { sessionId in
                /// Cascade delete pojedynczej sesji — atomically usuń athletes + session.
                /// Template zostaje (multi-session re-use pattern).
                try await database.write { db in
                    /// 1. Delete athleteSessionRecords FK do tej sesji.
                    try AthleteSessionRecord
                        .where { $0.classSessionId.eq(sessionId) }
                        .delete()
                        .execute(db)

                    /// 2. Delete session record.
                    try ClassSessionRecord
                        .find(sessionId)
                        .delete()
                        .execute(db)
                }
            },

            fetchAthletesForSession: { sessionId in
                try await database.read { db in
                    try AthleteSessionRecord
                        .where { $0.classSessionId.eq(sessionId) }
                        .order { $0.joinedAt.asc() }
                        .fetchAll(db)
                }
            },

            addAthlete: { classSessionId, deviceID, nick, maxHR in
                @Dependency(\.date.now) var now
                let encoder = JSONEncoder()
                let emptySamplesData = try encoder.encode([HRSample]())
                let emptyAnalyticsData = try encoder.encode(ClassAnalytics.empty)
                let id = UUID()
                return try await database.write { db in
                    /// Find-or-create INSIDE the write transaction: two quick payloads
                    /// from the same peer can pass the reducer's `athleteRecordIds`
                    /// check before the first `.athleteAdded` lands. SQLite serializes
                    /// writes, so the second call sees the first record here and
                    /// reuses it instead of inserting a duplicate (which showed up as
                    /// a doubled athlete in the class results). Predicate mirrors
                    /// `findAthlete`.
                    let existing = try AthleteSessionRecord
                        .where { $0.classSessionId.eq(classSessionId) && $0.deviceID.eq(deviceID) }
                        .fetchOne(db)
                    if let existingId = existing?.id {
                        return existingId
                    }
                    let draft = AthleteSessionRecord.Draft(
                        id: id,
                        classSessionId: classSessionId,
                        deviceID: deviceID,
                        nick: nick,
                        maxHR: maxHR,
                        hrSamplesData: emptySamplesData,
                        aggregatedStatsData: emptyAnalyticsData,
                        joinedAt: now,
                        leftAt: nil,
                        createdAt: now,
                        updatedAt: now
                    )
                    try AthleteSessionRecord.upsert { draft }.execute(db)
                    return id
                }
            },

            findAthlete: { classSessionId, deviceID in
                try await database.read { db in
                    try AthleteSessionRecord
                        .where { $0.classSessionId.eq(classSessionId) && $0.deviceID.eq(deviceID) }
                        .fetchOne(db)?
                        .id
                }
            },

            resumeAthlete: { athleteId in
                @Dependency(\.date.now) var now
                try await database.write { db in
                    let fetched = try AthleteSessionRecord
                        .where { $0.id.eq(athleteId) }
                        .fetchOne(db)
                    guard let athlete = fetched else { return }
                    /// Clear leftAt — athlete znowu active po reconnect. Zachowujemy
                    /// istniejące hrSamplesData + aggregatedStatsData; następne
                    /// appendHRSamples dorzuci nowe samples do istniejącego BLOB'u.
                    let draft = AthleteSessionRecord.Draft(
                        id: athlete.id,
                        classSessionId: athlete.classSessionId,
                        deviceID: athlete.deviceID,
                        nick: athlete.nick,
                        maxHR: athlete.maxHR,
                        hrSamplesData: athlete.hrSamplesData,
                        aggregatedStatsData: athlete.aggregatedStatsData,
                        joinedAt: athlete.joinedAt,
                        leftAt: nil,
                        createdAt: athlete.createdAt,
                        updatedAt: now
                    )
                    try AthleteSessionRecord.upsert { draft }.execute(db)
                }
            },

            appendHRSamples: { athleteId, newSamples in
                guard !newSamples.isEmpty else { return }
                @Dependency(\.date.now) var now
                let encoder = JSONEncoder()
                let decoder = JSONDecoder()
                try await database.write { db in
                    let fetched = try AthleteSessionRecord
                        .where { $0.id.eq(athleteId) }
                        .fetchOne(db)
                    guard let existing = fetched else { return }

                    var samples = (try? decoder.decode([HRSample].self, from: existing.hrSamplesData)) ?? []
                    samples.append(contentsOf: newSamples)
                    let encoded = try encoder.encode(samples)

                    let draft = AthleteSessionRecord.Draft(
                        id: existing.id,
                        classSessionId: existing.classSessionId,
                        deviceID: existing.deviceID,
                        nick: existing.nick,
                        maxHR: existing.maxHR,
                        hrSamplesData: encoded,
                        aggregatedStatsData: existing.aggregatedStatsData,
                        joinedAt: existing.joinedAt,
                        leftAt: existing.leftAt,
                        createdAt: existing.createdAt,
                        updatedAt: now
                    )
                    try AthleteSessionRecord.upsert { draft }.execute(db)
                }
            },

            endAthlete: { athleteId, leftAt in
                @Dependency(\.date.now) var now
                let encoder = JSONEncoder()
                let decoder = JSONDecoder()
                try await database.write { db in
                    let fetched = try AthleteSessionRecord
                        .where { $0.id.eq(athleteId) }
                        .fetchOne(db)
                    guard let athlete = fetched else { return }

                    /// Idempotent: jeśli już final (leftAt != nil — np. `endSession`
                    /// sfinalizował przed nami), skip.
                    guard athlete.leftAt == nil else { return }

                    let samples = (try? decoder.decode([HRSample].self, from: athlete.hrSamplesData)) ?? []
                    let duration = leftAt.timeIntervalSince(athlete.joinedAt)
                    let analytics = ClassAnalytics.compute(
                        samples: samples,
                        maxHR: athlete.maxHR,
                        duration: duration
                    )
                    let analyticsData = try encoder.encode(analytics)

                    let draft = AthleteSessionRecord.Draft(
                        id: athlete.id,
                        classSessionId: athlete.classSessionId,
                        deviceID: athlete.deviceID,
                        nick: athlete.nick,
                        maxHR: athlete.maxHR,
                        hrSamplesData: athlete.hrSamplesData,
                        aggregatedStatsData: analyticsData,
                        joinedAt: athlete.joinedAt,
                        leftAt: leftAt,
                        createdAt: athlete.createdAt,
                        updatedAt: now
                    )
                    try AthleteSessionRecord.upsert { draft }.execute(db)
                }
            }
        )
    }()

    static var testValue: GymClassClient {
        GymClassClient(
            fetchAllTemplates: unimplemented("GymClassClient.fetchAllTemplates", placeholder: []),
            saveTemplate: unimplemented("GymClassClient.saveTemplate"),
            deleteTemplate: unimplemented("GymClassClient.deleteTemplate"),
            fetchAllSessions: unimplemented("GymClassClient.fetchAllSessions", placeholder: []),
            startSession: unimplemented("GymClassClient.startSession", placeholder: UUID()),
            endSession: unimplemented("GymClassClient.endSession"),
            deleteSession: unimplemented("GymClassClient.deleteSession"),
            fetchAthletesForSession: unimplemented("GymClassClient.fetchAthletesForSession", placeholder: []),
            addAthlete: unimplemented("GymClassClient.addAthlete", placeholder: UUID()),
            findAthlete: unimplemented("GymClassClient.findAthlete", placeholder: nil),
            resumeAthlete: unimplemented("GymClassClient.resumeAthlete"),
            appendHRSamples: unimplemented("GymClassClient.appendHRSamples"),
            endAthlete: unimplemented("GymClassClient.endAthlete")
        )
    }
}
