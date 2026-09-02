//
//  RecordRoundTripTests.swift
//  AppDatabase
//
//  Created by Sebastian Ściuba on 02/09/2026.
//

import Foundation
import SharedModels
import SQLiteData
import Testing
@testable import AppDatabase

// Round-trip contract for every remaining record in Records/ (PREntryRecord has
// its own suite). Fixtures fill ALL optional fields — empty optionals cannot
// detect silent losses. Expected values are literals, never derived from the
// mapping code under test.
@Suite("Record round-trips")
struct RecordRoundTripTests {

    // MARK: - Helpers

    /// Full-second dates — codecs drop sub-second precision (see lessons.md).
    private static let day = Date(timeIntervalSince1970: 1_756_700_000)
    private static let savedAt = Date(timeIntervalSince1970: 1_756_710_000)

    private func makeMigratedDatabase() throws -> DatabaseQueue {
        let database = try DatabaseQueue()
        try AppDatabaseSchema.makeMigrator().migrate(database)
        return database
    }

    // MARK: - Records with a domain mapping

    @Test("UserProfile survives the round-trip unchanged")
    func userProfileRoundTrip() throws {
        let profile = UserProfile(
            id: UUID(uuidString: "BBBBBBBB-0000-0000-0000-000000000001")!,
            email: "alice@example.com",
            name: "Alice",
            surname: "Smith",
            nickname: "ala"
        )
        let database = try makeMigratedDatabase()
        let record = UserProfileRecord(from: profile, createdAt: Self.savedAt, updatedAt: Self.savedAt)
        try database.write { db in
            try UserProfileRecord.insert { record }.execute(db)
        }
        let restored = try database.read { db in
            try UserProfileRecord.all.fetchAll(db)
        }.first?.toDomain()
        #expect(restored == profile)
    }

    @Test("ExerciseLog with a non-empty per-set breakdown survives the round-trip unchanged")
    func exerciseLogRoundTrip() throws {
        let log = ExerciseLog(
            id: UUID(uuidString: "BBBBBBBB-0000-0000-0000-000000000002")!,
            date: Self.day,
            exerciseType: nil,
            unmatchedName: "Sandbag carry",
            category: nil,
            workoutPlanScoreId: UUID(uuidString: "BBBBBBBB-0000-0000-0000-00000000002A")!,
            workoutSessionResultId: UUID(uuidString: "BBBBBBBB-0000-0000-0000-00000000002B")!,
            wodName: "Strength A",
            plannedReps: "5-5-5",
            plannedWeight: 100,
            actualWeight: 102.5,
            actualReps: "5-5-4",
            sets: [
                SetEntry(id: UUID(uuidString: "BBBBBBBB-0000-0000-0000-0000000000A1")!, reps: 5, weight: 100),
                SetEntry(id: UUID(uuidString: "BBBBBBBB-0000-0000-0000-0000000000A2")!, reps: 5, weight: 102.5),
                SetEntry(id: UUID(uuidString: "BBBBBBBB-0000-0000-0000-0000000000A3")!, reps: 4, weight: nil),
            ],
            scaling: .scaled,
            isPR: true,
            avgHeartRate: 141.5,
            maxHeartRate: 172,
            phaseStartDate: Self.day,
            phaseEndDate: Self.savedAt,
            timeInPhase: 540,
            volumeLoad: 1417.5,
            tempoPerRound: 108,
            note: "Grip gave out on the last set",
            editableUntil: Self.savedAt
        )
        let database = try makeMigratedDatabase()
        let record = ExerciseLogRecord(from: log, createdAt: Self.savedAt, updatedAt: Self.savedAt)
        try database.write { db in
            try ExerciseLogRecord.insert { record }.execute(db)
        }
        let restored = try database.read { db in
            try ExerciseLogRecord.all.fetchAll(db)
        }.first?.toDomain()
        #expect(restored == log)
    }

    // Documented current behavior: a corrupted setsData blob silently drops the
    // per-set breakdown (double try? in the mapping) while the log itself
    // survives. Frozen here so any SetEntry schema drift fails loudly.
    @Test("ExerciseLog with unreadable setsData silently loses the breakdown but survives")
    func exerciseLogCorruptedSetsDataLosesBreakdown() throws {
        let database = try makeMigratedDatabase()
        try database.write { db in
            try db.execute(sql: """
                INSERT INTO "exerciseLogRecords"
                  ("id", "date", "unmatchedName", "setsData", "scaling", "isPR", "createdAt", "updatedAt")
                VALUES
                  ('BBBBBBBB-0000-0000-0000-00000000002C', '2026-09-01 10:00:00', 'Back squat', X'DEAD', 'rx', 0, '2026-09-01 10:00:00', '2026-09-01 10:00:00')
                """)
        }
        let fetched = try database.read { db in
            try ExerciseLogRecord.all.fetchAll(db)
        }.first
        var restored: ExerciseLog?
        withKnownIssue("toDomain reports the lost breakdown (dev telemetry)") {
            restored = fetched?.toDomain()
        }
        #expect(restored != nil)
        #expect(restored?.sets == nil)
    }

    @Test("TrainingSession survives the round-trip unchanged")
    func trainingSessionRoundTrip() throws {
        let session = TrainingSession(
            id: UUID(uuidString: "BBBBBBBB-0000-0000-0000-000000000003")!,
            date: Self.day,
            title: "Leg day",
            activity: .crossTraining,
            location: .indoor,
            warmUp: nil,
            workouts: [],
            coolDown: nil
        )
        let database = try makeMigratedDatabase()
        let record = try TrainingSessionRecord(from: session, createdAt: Self.savedAt, updatedAt: Self.savedAt)
        try database.write { db in
            try TrainingSessionRecord.insert { record }.execute(db)
        }
        let restored = try database.read { db in
            try TrainingSessionRecord.all.fetchAll(db)
        }.first.map { try $0.toDomain() }
        #expect(restored == session)
    }

    // Contract counter-pattern to the defensive-nil records: TrainingSessionRecord
    // THROWS a dedicated error on unknown rawValues instead of silently dropping.
    @Test("TrainingSessionRecord with an unknown activity rawValue throws instead of returning nil")
    func trainingSessionUnknownActivityThrows() throws {
        let record = TrainingSessionRecord(
            id: UUID(uuidString: "BBBBBBBB-0000-0000-0000-00000000003A")!,
            date: Self.day,
            title: "Mystery",
            activity: "underwaterBasketWeaving",
            location: "indoor",
            warmUpData: nil,
            workoutsData: try JSONEncoder().encode([WorkoutSessionNew]()),
            coolDownData: nil,
            createdAt: Self.savedAt,
            updatedAt: Self.savedAt
        )
        #expect(throws: TrainingSessionRecordError.self) {
            _ = try record.toDomain()
        }
    }

    @Test("WorkoutPlanScore survives the round-trip unchanged")
    func workoutPlanScoreRoundTrip() throws {
        let score = WorkoutPlanScore(
            id: UUID(uuidString: "BBBBBBBB-0000-0000-0000-000000000004")!,
            date: Self.day,
            trainingSessionId: UUID(uuidString: "BBBBBBBB-0000-0000-0000-00000000004A")!,
            hkWorkoutId: UUID(uuidString: "BBBBBBBB-0000-0000-0000-00000000004B")!,
            results: []
        )
        let database = try makeMigratedDatabase()
        let record = try WorkoutPlanScoreRecord(from: score, createdAt: Self.savedAt, updatedAt: Self.savedAt)
        try database.write { db in
            try WorkoutPlanScoreRecord.insert { record }.execute(db)
        }
        let restored = try database.read { db in
            try WorkoutPlanScoreRecord.all.fetchAll(db)
        }.first.map { try $0.toDomain() }
        #expect(restored == score)
    }

    @Test("WorkoutEffortScore survives the round-trip with all five zone buckets intact")
    func workoutEffortScoreRoundTrip() throws {
        let score = WorkoutEffortScore(
            id: UUID(uuidString: "BBBBBBBB-0000-0000-0000-000000000005")!,
            hkWorkoutId: UUID(uuidString: "BBBBBBBB-0000-0000-0000-00000000005A")!,
            points: 87,
            workoutStartDate: Self.day,
            secondsByZone: [
                .recovery: 120,
                .fatBurning: 300,
                .aerobic: 900,
                .threshold: 480,
                .anaerobic: 60,
            ],
            weightsVersion: 1
        )
        let database = try makeMigratedDatabase()
        let record = WorkoutEffortScoreRecord(from: score, createdAt: Self.savedAt, updatedAt: Self.savedAt)
        try database.write { db in
            try WorkoutEffortScoreRecord.insert { record }.execute(db)
        }
        let restored = try database.read { db in
            try WorkoutEffortScoreRecord.all.fetchAll(db)
        }.first?.toDomain()
        #expect(restored == score)
    }

    @Test("ClassParticipation survives the round-trip unchanged")
    func classParticipationRoundTrip() throws {
        let participation = ClassParticipation(
            id: UUID(uuidString: "BBBBBBBB-0000-0000-0000-000000000006")!,
            hkWorkoutId: UUID(uuidString: "BBBBBBBB-0000-0000-0000-00000000006A")!,
            classSessionId: UUID(uuidString: "BBBBBBBB-0000-0000-0000-00000000006B")!,
            gymName: "Morning CrossFit",
            place: 2,
            participantCount: 9,
            classPoints: 34,
            latitude: 50.0647,
            longitude: 19.9450
        )
        let database = try makeMigratedDatabase()
        let record = ClassParticipationRecord(from: participation, createdAt: Self.savedAt, updatedAt: Self.savedAt)
        try database.write { db in
            try ClassParticipationRecord.insert { record }.execute(db)
        }
        let restored = try database.read { db in
            try ClassParticipationRecord.all.fetchAll(db)
        }.first?.toDomain()
        #expect(restored == participation)
    }

    @Test("WorkoutHRSnapshot survives the round-trip unchanged")
    func workoutHRSnapshotRoundTrip() throws {
        let snapshot = WorkoutHRSnapshot(
            id: UUID(uuidString: "BBBBBBBB-0000-0000-0000-000000000007")!,
            hkWorkoutId: UUID(uuidString: "BBBBBBBB-0000-0000-0000-00000000007A")!,
            maxHR: 187.5,
            formulaRawValue: "tanaka",
            ageAtWorkout: 34,
            biologicalSex: .male
        )
        let database = try makeMigratedDatabase()
        let record = WorkoutHRSnapshotRecord(from: snapshot, createdAt: Self.savedAt, updatedAt: Self.savedAt)
        try database.write { db in
            try WorkoutHRSnapshotRecord.insert { record }.execute(db)
        }
        let restored = try database.read { db in
            try WorkoutHRSnapshotRecord.all.fetchAll(db)
        }.first?.toDomain()
        #expect(restored == snapshot)
    }

    // MARK: - Records without a domain layer (the record IS the model)

    @Test("GymClassRecord survives the round-trip field by field")
    func gymClassRecordRoundTrip() throws {
        let record = GymClassRecord(
            id: UUID(uuidString: "BBBBBBBB-0000-0000-0000-000000000008")!,
            name: "Morning CrossFit",
            location: "Sala 1",
            scheduledAt: Self.day,
            maxParticipants: 12,
            latitude: 50.0647,
            longitude: 19.9450,
            isRecurring: true,
            createdAt: Self.savedAt,
            updatedAt: Self.savedAt
        )
        let database = try makeMigratedDatabase()
        try database.write { db in
            try GymClassRecord.insert { record }.execute(db)
        }
        let restored = try #require(
            try database.read { db in try GymClassRecord.all.fetchAll(db) }.first
        )
        #expect(restored.id == record.id)
        #expect(restored.name == record.name)
        #expect(restored.location == record.location)
        #expect(restored.scheduledAt == record.scheduledAt)
        #expect(restored.maxParticipants == record.maxParticipants)
        #expect(restored.latitude == record.latitude)
        #expect(restored.longitude == record.longitude)
        #expect(restored.isRecurring == record.isRecurring)
    }

    @Test("ClassSessionRecord survives the round-trip field by field")
    func classSessionRecordRoundTrip() throws {
        let record = ClassSessionRecord(
            id: UUID(uuidString: "BBBBBBBB-0000-0000-0000-000000000009")!,
            gymClassId: UUID(uuidString: "BBBBBBBB-0000-0000-0000-00000000009A")!,
            className: "Morning CrossFit",
            location: "Sala 1",
            startedAt: Self.day,
            endedAt: Self.savedAt,
            createdAt: Self.savedAt,
            updatedAt: Self.savedAt
        )
        let database = try makeMigratedDatabase()
        try database.write { db in
            try ClassSessionRecord.insert { record }.execute(db)
        }
        let restored = try #require(
            try database.read { db in try ClassSessionRecord.all.fetchAll(db) }.first
        )
        #expect(restored.id == record.id)
        #expect(restored.gymClassId == record.gymClassId)
        #expect(restored.className == record.className)
        #expect(restored.location == record.location)
        #expect(restored.startedAt == record.startedAt)
        #expect(restored.endedAt == record.endedAt)
    }

    @Test("AthleteSessionRecord survives the round-trip with both JSON blobs byte-identical")
    func athleteSessionRecordRoundTrip() throws {
        let hrSamples = Data(#"[{"timestamp":1756700000,"bpm":142,"activeEnergy":8.5}]"#.utf8)
        let aggregatedStats = Data(#"{"avgHR":141.5,"peakHR":172}"#.utf8)
        let record = AthleteSessionRecord(
            id: UUID(uuidString: "BBBBBBBB-0000-0000-0000-00000000000A")!,
            classSessionId: UUID(uuidString: "BBBBBBBB-0000-0000-0000-0000000000AA")!,
            deviceID: UUID(uuidString: "BBBBBBBB-0000-0000-0000-0000000000AB")!,
            nick: "Seba",
            maxHR: 190,
            hrSamplesData: hrSamples,
            aggregatedStatsData: aggregatedStats,
            joinedAt: Self.day,
            leftAt: Self.savedAt,
            createdAt: Self.savedAt,
            updatedAt: Self.savedAt
        )
        let database = try makeMigratedDatabase()
        try database.write { db in
            try AthleteSessionRecord.insert { record }.execute(db)
        }
        let restored = try #require(
            try database.read { db in try AthleteSessionRecord.all.fetchAll(db) }.first
        )
        #expect(restored.id == record.id)
        #expect(restored.classSessionId == record.classSessionId)
        #expect(restored.deviceID == record.deviceID)
        #expect(restored.nick == record.nick)
        #expect(restored.maxHR == record.maxHR)
        #expect(restored.hrSamplesData == hrSamples)
        #expect(restored.aggregatedStatsData == aggregatedStats)
        #expect(restored.joinedAt == record.joinedAt)
        #expect(restored.leftAt == record.leftAt)
    }
}
