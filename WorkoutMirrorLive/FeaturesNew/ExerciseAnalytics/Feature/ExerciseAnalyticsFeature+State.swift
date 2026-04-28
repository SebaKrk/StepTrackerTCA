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

        // MARK: - Computed

        /// Groups logs by exercise type and returns sorted summaries for the list.
        var exerciseSummaries: [ExerciseSummary] {
            let grouped = Dictionary(grouping: exerciseLogs) { $0.exerciseType ?? .unknown }
            return grouped.map { type, logs in
                ExerciseSummary(
                    exerciseType: type,
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

        /// Weekly breakdown for stacked bar chart — one dictionary per week.
        var weeklyBreakdown: [[MovementCategory: Int]] {
            let calendar = Calendar.current
            let grouped = Dictionary(grouping: exerciseLogs) { log in
                calendar.component(.weekOfMonth, from: log.date)
            }
            let maxWeek = grouped.keys.max() ?? 4
            return (1...maxWeek).map { week in
                let logs = grouped[week] ?? []
                return Dictionary(grouping: logs) { $0.category ?? .mixed }
                    .mapValues(\.count)
            }
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

    var id: ExerciseType { exerciseType }

    /// The exercise this summary represents.
    let exerciseType: ExerciseType

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
