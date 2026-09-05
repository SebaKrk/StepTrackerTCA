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

        /// User-picked chart year; nil = auto (the latest year with entries).
        var selectedChartYear: Int?

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

        // MARK: - Layout

        /// Layout state of the detail screen (FR-009: chart from the second entry on).
        enum Layout {
            /// No entries — invitation to add the first result.
            case empty
            /// One entry — hero and history, no chart yet.
            case single
            /// Two or more entries — full layout with the progress chart.
            case progressing
        }

        /// Drives the layout `switch` in the view.
        var layout: Layout {
            if entries.isEmpty { return .empty }
            return entries.count >= 2 ? .progressing : .single
        }

        // MARK: - Chart (S-06)

        /// Time scores invert the Y axis — a shorter (better) time plots higher.
        var isTimeScored: Bool { movement.scoreType == .time }

        /// Entries whose score type matches the movement — one axis, one unit
        /// (as in the D4 partition of PRResolver).
        private var typeMatchingEntries: [PREntry] {
            entries.filter { $0.score.scoreType == movement.scoreType }
        }

        /// Years having chartable entries, newest first; the picker renders from 2 up.
        var availableChartYears: [Int] {
            Set(typeMatchingEntries.map { Self.year(of: $0.date) }).sorted(by: >)
        }

        /// The picked year while it still has data, else the newest year with data —
        /// mixing years on one axis squeezes the points into unreadable clusters.
        var effectiveChartYear: Int? {
            if let selectedChartYear, availableChartYears.contains(selectedChartYear) {
                return selectedChartYear
            }
            return availableChartYears.first
        }

        /// Chart data of the effective year, ascending by date; score collapsed
        /// to one scalar per type (weight kg, time seconds, rep count, AMRAP
        /// rounds + extraReps/100 — monotonic with the lexicographic comparison).
        var chartPoints: [ChartPoint] {
            typeMatchingEntries
                .filter { Self.year(of: $0.date) == effectiveChartYear }
                .reversed()
                .map { entry in
                    ChartPoint(
                        id: entry.id,
                        date: entry.date,
                        value: Self.scalar(for: entry.score),
                        standard: standardLabel(for: entry)
                    )
                }
        }

        /// Rx and scaled attempts are separate populations (S-04) — one mixed
        /// line would fake progress on a standard switch; nil = single series.
        private func standardLabel(for entry: PREntry) -> String? {
            guard movement.supportsRxScaled else { return nil }
            return entry.isRx == true ? "Rx" : String(localized: "Scaled")
        }

        private static func year(of date: Date) -> Int {
            Calendar.current.component(.year, from: date)
        }

        /// One plotted sample of the progress chart.
        struct ChartPoint: Identifiable, Equatable {
            /// Source entry id (stable ForEach identity).
            let id: UUID
            /// Day of the result (X axis).
            let date: Date
            /// Scalarized score (Y axis).
            let value: Double
            /// Series label on Rx/scaled benchmarks ("Rx"/"Scaled"); nil = single series.
            let standard: String?
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
