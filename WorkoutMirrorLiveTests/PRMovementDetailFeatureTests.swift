//
//  PRMovementDetailFeatureTests.swift
//  WorkoutMirrorLiveTests
//
//  Created by Sebastian Ściuba on 03/09/2026.
//

import AppDatabase
import ComposableArchitecture
import Foundation
import SharedModels
import SQLiteData
import Testing

@testable import WorkoutMirrorLive

// Regression test born from a bug (M3L5, debugging-as-test): a failed delete
// was swallowed (catch + reportIssue only) — the user tapped "Delete entry",
// nothing happened, and no feedback explained why. The failing test below was
// written BEFORE the fix; the fix mirrors the save-failure alert pattern of
// PREntryEditorFeature. State holds @FetchAll (non-Equatable by repo
// convention), so this drives a plain Store and asserts on state + database.
@MainActor
struct PRMovementDetailFeatureTests {

    /// Fixed reference date — fixtures never use `.now` (lessons.md).
    private static let fixedNow = Date(timeIntervalSince1970: 1_756_684_800)

    @Test
    func deleteFailureShowsAlertAndKeepsEntry() async throws {
        struct DeleteError: Error {}
        let movement = try #require(PRCatalog.movement(id: "back-squat"))

        // Migrated in-memory database seeded with one entry — the delete target.
        let database = try DatabaseQueue()
        try AppDatabaseSchema.makeMigrator().migrate(database)
        let entry = PREntry(
            id: UUID(uuidString: "CCCCCCCC-0000-0000-0000-000000000001")!,
            movementId: movement.id,
            date: Self.fixedNow,
            createdAt: Self.fixedNow,
            score: .weight(kilograms: 150)
        )
        // Captured before the Sendable write closure — the @MainActor-isolated
        // static cannot be referenced from inside it (Swift 6).
        let record = PREntryRecord(from: entry, updatedAt: Self.fixedNow)
        try await database.write { db in
            try PREntryRecord.insert { record }.execute(db)
        }

        let store = Store(
            initialState: PRMovementDetailFeature.State(movement: movement)
        ) {
            PRMovementDetailFeature()
        } withDependencies: {
            $0.defaultDatabase = database
            $0.prEntryClient.delete = { _ in throw DeleteError() }
            $0.date = .constant(Self.fixedNow)
        }

        store.send(.view(.deleteEntryTapped(entry)))
        #expect(store.confirmationDialog != nil)

        // The reducer reports the caught error (dev telemetry) — expected here.
        await withKnownIssue("delete failure is reported via reportIssue") {
            await store.send(.confirmationDialog(.presented(.confirmDelete(entry.id)))).finish()
        }

        // The user must SEE the failure: alert presented, entry still in place.
        #expect(store.alert != nil)
        let remaining = try await database.read { db in
            try PREntryRecord.all.fetchCount(db)
        }
        #expect(remaining == 1)
    }
}
