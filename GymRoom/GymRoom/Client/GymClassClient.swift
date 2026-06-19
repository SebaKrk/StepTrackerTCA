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

    // MARK: - Athletes (AthleteSessionRecord)

    /// Returns: `athleteId` (UUID) do batch HR persistence keyed po nim.
    var addAthlete: @Sendable (_ classSessionId: UUID, _ deviceID: UUID, _ nick: String, _ maxHR: Int) async throws -> UUID

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
                try await database.write { db in
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
                    // 1. Set endedAt na session'ie (read existing → build draft z modifications).
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

                    // 2. Finalize wszystkich ongoing athletes (leftAt == nil).
                    // Compute analytics z BLOB samples + set leftAt = endedAt klasy.
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

            addAthlete: { classSessionId, deviceID, nick, maxHR in
                @Dependency(\.date.now) var now
                let encoder = JSONEncoder()
                let emptySamplesData = try encoder.encode([HRSample]())
                let emptyAnalyticsData = try encoder.encode(ClassAnalytics.empty)
                let id = UUID()
                try await database.write { db in
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
                }
                return id
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

                    // Idempotent: jeśli już final (leftAt != nil — np. `endSession`
                    // sfinalizował przed nami), skip.
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
            addAthlete: unimplemented("GymClassClient.addAthlete", placeholder: UUID()),
            appendHRSamples: unimplemented("GymClassClient.appendHRSamples"),
            endAthlete: unimplemented("GymClassClient.endAthlete")
        )
    }
}
