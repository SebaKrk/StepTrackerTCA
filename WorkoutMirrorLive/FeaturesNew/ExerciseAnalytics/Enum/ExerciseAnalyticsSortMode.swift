//
//  ExerciseAnalyticsSortMode.swift
//  MyFitnessJournal
//

import Foundation

/// Controls how the exercise list is ordered in `ExerciseAnalyticsView`.
///
/// The user switches between modes via a segmented picker.
/// Each mode sorts `ExerciseSummary` by a different metric.
enum ExerciseAnalyticsSortMode: String, CaseIterable {

    /// Sort by number of occurrences in the selected month (most frequent first).
    case frequency

    /// Sort by heaviest `actualWeight` recorded (heaviest first). Bodyweight exercises appear at the bottom.
    case weight

    /// Sort by total `volumeLoad` (reps × weight, highest first).
    case volume
}
