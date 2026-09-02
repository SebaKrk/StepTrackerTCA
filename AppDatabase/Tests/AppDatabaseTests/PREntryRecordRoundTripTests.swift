//
//  PREntryRecordRoundTripTests.swift
//  AppDatabase
//
//  Created by Sebastian Ściuba on 02/09/2026.
//

import Foundation
import SharedModels
import SQLiteData
import Testing
@testable import AppDatabase

// Round-trip contract of PREntryRecord: every score type survives
// domain -> record -> real SQL -> record -> domain with all fields intact,
// and the defensive read paths (unknown rawValues) behave as documented.
// Expected values are literals on purpose — never derived from the mapping
// code under test (oracle problem).
@Suite("PREntryRecord round-trip")
struct PREntryRecordRoundTripTests {

    // MARK: - Helpers

    /// Full-second dates — codecs drop sub-second precision (see lessons.md).
    private static let entryDate = Date(timeIntervalSince1970: 1_756_800_000)
    private static let savedAt = Date(timeIntervalSince1970: 1_756_803_600)

    private func makeMigratedDatabase() throws -> DatabaseQueue {
        let database = try DatabaseQueue()
        try AppDatabaseSchema.makeMigrator().migrate(database)
        return database
    }

    /// Writes the entry through the record mapping into real SQL and reads it back.
    private func roundTrip(_ entry: PREntry) throws -> PREntry? {
        let database = try makeMigratedDatabase()
        let record = PREntryRecord(from: entry, updatedAt: Self.savedAt)
        try database.write { db in
            try PREntryRecord.insert { record }.execute(db)
        }
        let fetched = try database.read { db in
            try PREntryRecord.all.fetchAll(db)
        }
        #expect(fetched.count == 1)
        return fetched.first?.toDomain()
    }

    // MARK: - Happy path: one test per score type

    @Test("Weight entry with full metadata survives the round-trip unchanged")
    func weightRoundTrip() throws {
        let entry = PREntry(
            id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000001")!,
            movementId: "back-squat",
            date: Self.entryDate,
            createdAt: Self.savedAt,
            score: .weight(kilograms: 150.5),
            isRx: true,
            equipment: [.chalk, .belt],
            rpe: 8.5,
            note: "New PR, felt heavy",
            bodyWeightKg: 82.4,
            context: .competition
        )
        #expect(try roundTrip(entry) == entry)
    }

    @Test("Time entry survives the round-trip unchanged")
    func timeRoundTrip() throws {
        let entry = PREntry(
            id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000002")!,
            movementId: "fran",
            date: Self.entryDate,
            createdAt: Self.savedAt,
            score: .time(seconds: 390),
            isRx: false,
            context: .inWod
        )
        #expect(try roundTrip(entry) == entry)
    }

    @Test("Reps entry survives the round-trip and stays .reps despite sharing the rounds column")
    func repsRoundTrip() throws {
        let entry = PREntry(
            id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000003")!,
            movementId: "pull-up",
            date: Self.entryDate,
            createdAt: Self.savedAt,
            score: .reps(count: 21)
        )
        let restored = try roundTrip(entry)
        #expect(restored == entry)
        #expect(restored?.score == .reps(count: 21))
    }

    @Test("AMRAP entry survives the round-trip unchanged")
    func amrapRoundTrip() throws {
        let entry = PREntry(
            id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000004")!,
            movementId: "cindy",
            date: Self.entryDate,
            createdAt: Self.savedAt,
            score: .amrap(rounds: 6, extraReps: 7),
            isRx: true,
            equipment: [.weightVest]
        )
        #expect(try roundTrip(entry) == entry)
    }

    @Test("Equipment is stored as a comma-joined, sorted rawValue list")
    func equipmentStoredSorted() throws {
        let entry = PREntry(
            id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000005")!,
            movementId: "deadlift",
            date: Self.entryDate,
            createdAt: Self.savedAt,
            score: .weight(kilograms: 180),
            equipment: [.straps, .belt, .chalk]
        )
        let record = PREntryRecord(from: entry, updatedAt: Self.savedAt)
        #expect(record.equipment == "belt,chalk,straps")
    }

    // MARK: - Defensive read paths (documented current behavior)

    // A row whose scoreType is unreadable is physically in the database but
    // invisible to every list, counter, and PR calculation (compactMap in the
    // PRBoard States). These tests freeze that contract so any rawValue rename
    // fails loudly here instead of silently dropping user data.

    @Test("Unknown scoreType: row stays in the database but toDomain collapses to nil")
    func unknownScoreTypeCollapsesToNil() throws {
        let database = try makeMigratedDatabase()
        try database.write { db in
            try db.execute(sql: """
                INSERT INTO "prEntryRecords"
                  ("id", "movementId", "date", "scoreType", "weightKg", "equipment", "context", "createdAt", "updatedAt")
                VALUES
                  ('AAAAAAAA-0000-0000-0000-00000000000A', 'back-squat', '2026-09-01 10:00:00', 'distance', 5000.0, '', 'fresh', '2026-09-01 10:00:00', '2026-09-01 10:00:00')
                """)
        }
        let fetched = try database.read { db in
            try PREntryRecord.all.fetchAll(db)
        }
        #expect(fetched.count == 1)
        #expect(fetched.first?.toDomain() == nil)
    }

    @Test("Unknown equipment token is silently filtered; the entry itself survives")
    func unknownEquipmentTokenIsFiltered() throws {
        let database = try makeMigratedDatabase()
        try database.write { db in
            try db.execute(sql: """
                INSERT INTO "prEntryRecords"
                  ("id", "movementId", "date", "scoreType", "weightKg", "equipment", "context", "createdAt", "updatedAt")
                VALUES
                  ('AAAAAAAA-0000-0000-0000-00000000000B', 'back-squat', '2026-09-01 10:00:00', 'weight', 100.0, 'belt,jetpack', 'fresh', '2026-09-01 10:00:00', '2026-09-01 10:00:00')
                """)
        }
        let restored = try database.read { db in
            try PREntryRecord.all.fetchAll(db)
        }.first?.toDomain()
        #expect(restored != nil)
        #expect(restored?.equipment == [.belt])
    }

    @Test("Unknown context rawValue is silently rewritten to .fresh")
    func unknownContextFallsBackToFresh() throws {
        let database = try makeMigratedDatabase()
        try database.write { db in
            try db.execute(sql: """
                INSERT INTO "prEntryRecords"
                  ("id", "movementId", "date", "scoreType", "weightKg", "equipment", "context", "createdAt", "updatedAt")
                VALUES
                  ('AAAAAAAA-0000-0000-0000-00000000000C', 'back-squat', '2026-09-01 10:00:00', 'weight', 100.0, '', 'warmup', '2026-09-01 10:00:00', '2026-09-01 10:00:00')
                """)
        }
        let restored = try database.read { db in
            try PREntryRecord.all.fetchAll(db)
        }.first?.toDomain()
        #expect(restored?.context == .fresh)
    }
}
