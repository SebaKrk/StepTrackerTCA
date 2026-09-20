//
//  ExerciseAnalyticsFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 24/04/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension ExerciseAnalyticsFeature {

    @ObservableState
    struct State {

        // MARK: - Properties

        /// Currently displayed month — controls which logs are fetched and shown.
        /// Set to current date on `onAppear` via `@Dependency(\.date.now)`.
        var selectedMonth: Date = .distantPast

        /// All `ExerciseLog` entries for the selected month, fetched from database.
        var exerciseLogs: [ExerciseLog] = []

        /// Active sort mode for the exercise list (frequency / weight / volume).
        var sortMode: ExerciseAnalyticsSortMode = .frequency

        /// Controls chart reveal animation — set to `true` after data loads.
        var isChartAnimated: Bool = false

        /// Weekly breakdown for stacked bar chart — one dictionary per week.
        /// Recomputed by the reducer on `.logsLoaded` using `@Dependency(\.calendar)`.
        var weeklyBreakdown: [[MovementCategory: Int]] = []

        // MARK: - Destination

        /// Navigation destination for exercise detail drilldown.
        @Presents var detail: ExerciseDetailFeature.State?

        // MARK: - Computed

        /// Groups logs by exercise type and returns sorted summaries for the list.
        var exerciseSummaries: [ExerciseSummary] {
            // Rows are identified by movement AND implement, so a dumbbell variant
            // tracks its own progress instead of blending into the default one.
            let grouped = Dictionary(grouping: exerciseLogs) {
                ExerciseIdentity(type: $0.exerciseType ?? .unknown, equipment: $0.effectiveEquipment)
            }
            return grouped.map { identity, logs in
                let type = identity.type
                return ExerciseSummary(
                    exerciseType: type,
                    equipment: identity.equipment,
                    count: logs.count,
                    maxWeight: logs.compactMap(\.actualWeight).max(),
                    totalVolume: logs.compactMap(\.volumeLoad).reduce(0, +),
                    lastDate: logs.compactMap(\.date).max(),
                    category: type.category,
                    hasPR: logs.contains(where: \.isPR)
                )
            }
            .sorted { sortComparator($0, $1) }
        }

        /// Category breakdown for the overall pie/legend.
        var categoryBreakdown: [MovementCategory: Int] {
            Dictionary(grouping: exerciseLogs) { $0.category ?? .mixed }
                .mapValues(\.count)
        }

        /// Compares two summaries according to the active `sortMode`.
        private func sortComparator(_ a: ExerciseSummary, _ b: ExerciseSummary) -> Bool {
            switch sortMode {
            case .frequency: return a.count > b.count
            case .weight: return (a.maxWeight ?? 0) > (b.maxWeight ?? 0)
            case .volume: return a.totalVolume > b.totalVolume
            }
        }
    }
}

// MARK: - ExerciseSummary

/// Aggregated summary of a single exercise type across multiple `ExerciseLog` entries.
///
/// Built by `ExerciseAnalyticsFeature.State.exerciseSummaries` — groups all logs by `ExerciseType`
/// and calculates frequency, max weight, total volume, and PR status.
/// Used to populate the exercise list in `ExerciseAnalyticsView`.
struct ExerciseSummary: Identifiable, Equatable {

    var id: ExerciseIdentity { ExerciseIdentity(type: exerciseType, equipment: equipment) }

    /// The exercise this summary represents.
    let exerciseType: ExerciseType

    /// Implement in play; `nil` when the movement has no usual one.
    let equipment: Equipment?

    /// Name for the list row — without this the two implement variants of one
    /// movement would split into separate rows carrying the same label.
    var displayName: String { exerciseType.displayName(with: equipment) }

    /// How many times this exercise appeared in the selected month.
    let count: Int

    /// Heaviest weight used across all occurrences. `nil` for bodyweight exercises.
    let maxWeight: Double?

    /// Sum of `volumeLoad` (total reps × weight) across all occurrences.
    let totalVolume: Double

    /// Most recent date this exercise was performed.
    let lastDate: Date?

    /// Movement category for chart grouping (strength, olympic, gymnastics, cardio, mixed).
    let category: MovementCategory

    /// Whether any occurrence was marked as a personal record.
    let hasPR: Bool
}

// MARK: - Exercise Identity

/// Identity of a row in the exercise list: the movement plus the implement it was
/// actually performed with. Uses the effective implement, so "snatch" and
/// "barbell snatch" stay one row — they mean the same thing.
struct ExerciseIdentity: Hashable {

    /// Movement from the catalog.
    let type: ExerciseType

    /// Implement in play: stated in the plan text, else the movement's default.
    let equipment: Equipment?
}
