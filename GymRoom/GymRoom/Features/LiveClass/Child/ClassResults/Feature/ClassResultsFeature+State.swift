//
//  ClassResultsFeature+State.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 09/07/2026.
//

import ComposableArchitecture
import Foundation

extension ClassResultsFeature {

    @ObservableState
    struct State: Equatable {

        /// Class name shown as the screen title — snapshot from `LiveClassFeature`.
        var className: String = ""

        /// One row per athlete who took part in the session (including those who
        /// left mid-class) — built from the FROZEN `ClassAnalytics` persisted by
        /// `endSession`. Never recomputed ("a result is a result").
        var rows: [ResultRow] = []

        /// Current `Table` sort — points descending by default ("who earned the
        /// most"). Column-header taps rebind it through `BindingReducer`.
        var sortOrder: [KeyPathComparator<ResultRow>] = [
            KeyPathComparator(\.points, order: .reverse)
        ]

        /// Rows in the order the `Table` displays them.
        var sortedRows: [ResultRow] {
            rows.sorted(using: sortOrder)
        }

        /// Stable ranking by points (1 = winner) — independent of the current
        /// column sort, so medals do not jump around when the trainer re-sorts
        /// the table by another column.
        var pointsRank: [ResultRow.ID: Int] {
            let byPoints = rows.sorted { $0.points > $1.points }
            return Dictionary(
                uniqueKeysWithValues: byPoints.enumerated().map { ($0.element.id, $0.offset + 1) }
            )
        }

        // MARK: - Header stats (same definitions as ClassHistoryDetail's banner)

        /// Total calories burned by the whole class (sum over athletes).
        var totalCalories: Int {
            rows.reduce(0) { $0 + $1.calories }
        }

        /// Mean of the athletes' average HRs; `nil` for an empty class ("—").
        var averageHR: Int? {
            guard !rows.isEmpty else { return nil }
            return rows.reduce(0) { $0 + $1.avgHR } / rows.count
        }

        /// Class duration approximated by the LONGEST participation — session
        /// start/end timestamps are not part of this snapshot, and in practice
        /// the earliest joiner stays for the whole class.
        var classDurationMinutes: Int {
            rows.map(\.durationMinutes).max() ?? 0
        }
    }

    /// Flat table row — plain stored properties so `KeyPathComparator` works
    /// directly for every sortable column.
    ///
    /// `nonisolated` — built inside the `confirmEnd` `.run` effect (nonisolated
    /// context) under the project's `defaultIsolation(MainActor.self)`.
    nonisolated struct ResultRow: Identifiable, Sendable, Equatable {

        /// `AthleteSessionRecord.id` — stable per participation in this session.
        let id: UUID

        /// Display name (may repeat between athletes — `id` is the identity).
        let nick: String

        /// Frozen effort points; `0` when the peer build did not send them
        /// (`hasPoints == false` → the cell shows a dash instead of a zero).
        let points: Int

        /// `false` = legacy peer without effort points support.
        let hasPoints: Bool

        /// Average heart rate over the athlete's participation (bpm).
        let avgHR: Int

        /// Peak heart rate (bpm).
        let peakHR: Int

        /// Total active calories (kcal, rounded).
        let calories: Int

        /// Participation time in whole minutes.
        let durationMinutes: Int
    }
}
