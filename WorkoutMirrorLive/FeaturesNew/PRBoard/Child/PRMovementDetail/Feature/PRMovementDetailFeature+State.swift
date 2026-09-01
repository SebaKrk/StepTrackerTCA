//
//  PRMovementDetailFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 01/09/2026.
//

import AppDatabase
import ComposableArchitecture
import Foundation
import SharedModels
import SQLiteData

extension PRMovementDetailFeature {

    @ObservableState
    struct State {

        // MARK: - Properties

        /// Catalog movement this detail screen presents.
        let movement: PRMovement

        /// "Add result" editor sheet, presented from the toolbar or the empty state.
        @Presents var editor: PREntryEditorFeature.State?

        /// Destructive confirmation shown before deleting a history entry (FR-006).
        @Presents var confirmationDialog: ConfirmationDialogState<Action.Dialog>?

        // MARK: - Observed entries

        /// Observed PR entries (SQLiteData) — the hero value and history refresh
        /// automatically after every save. `@ObservationStateIgnored` — FetchAll
        /// observes itself.
        @ObservationStateIgnored
        @FetchAll(PREntryRecord.all)
        var entryRecords

        // MARK: - Derived

        /// This movement's entries, newest first (date, then save timestamp).
        var entries: [PREntry] {
            entryRecords
                .compactMap { $0.toDomain() }
                .filter { $0.movementId == movement.id }
                .sorted { lhs, rhs in
                    lhs.date != rhs.date ? lhs.date > rhs.date : lhs.createdAt > rhs.createdAt
                }
        }

        /// Current PRs derived purely from history (FR-007).
        var summary: PRSummary {
            PRResolver.summary(for: movement, entries: entries)
        }

        // MARK: - Init

        init(movement: PRMovement) {
            self.movement = movement
        }
    }
}
