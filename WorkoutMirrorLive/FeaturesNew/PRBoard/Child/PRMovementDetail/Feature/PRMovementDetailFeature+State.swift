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

        /// Delete-failure alert; a failed delete must be visible, never silent.
        @Presents var alert: AlertState<Action.Alert>?

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

        /// S-02 scope guard: the entry form supports weight scores only —
        /// time/reps/AMRAP controls arrive with S-03, which lifts this flag.
        var supportsEntryForm: Bool { movement.scoreType == .weight }

        /// Body-weight multiple of the current weight PR ("×1.88 BW"); nil for
        /// non-weight scores or entries saved without a body-weight snapshot.
        var bodyWeightMultiple: Double? {
            guard
                let best = summary.best,
                case let .weight(kilograms) = best.score,
                let bodyWeight = best.bodyWeightKg,
                bodyWeight > 0
            else { return nil }
            return kilograms / bodyWeight
        }

        // MARK: - Chart (S-06)

        /// FR-009: the progress chart renders only from the second entry on.
        var showsChart: Bool { entries.count >= 2 }

        /// Time scores invert the Y axis — a shorter (better) time plots higher.
        var isTimeScored: Bool { movement.scoreType == .time }

        /// Chart data ascending by date; score collapsed to one scalar per type
        /// (weight kg, time seconds, rep count, AMRAP rounds + extraReps/100 —
        /// monotonic with the lexicographic comparison).
        var chartPoints: [ChartPoint] {
            entries.reversed().map { entry in
                ChartPoint(id: entry.id, date: entry.date, value: Self.scalar(for: entry.score))
            }
        }

        /// One plotted sample of the progress chart.
        struct ChartPoint: Identifiable, Equatable {
            /// Source entry id (stable ForEach identity).
            let id: UUID
            /// Day of the result (X axis).
            let date: Date
            /// Scalarized score (Y axis).
            let value: Double
        }

        private static func scalar(for score: PRScoreValue) -> Double {
            switch score {
            case let .weight(kilograms): return kilograms
            case let .time(seconds): return Double(seconds)
            case let .reps(count): return Double(count)
            case let .amrap(rounds, extraReps): return Double(rounds) + Double(extraReps) / 100
            }
        }

        // MARK: - Init

        init(movement: PRMovement) {
            self.movement = movement
        }
    }
}
