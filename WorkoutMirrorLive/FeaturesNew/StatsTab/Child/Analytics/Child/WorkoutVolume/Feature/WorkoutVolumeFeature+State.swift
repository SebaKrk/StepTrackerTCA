//
//  WorkoutVolumeFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 16/04/2026.
//

import ComposableArchitecture
import SharedModels

extension WorkoutVolumeFeature {

    @ObservableState
    struct State {

        /// Current loading state of the chart.
        var viewState: ViewState = .loading

        /// Selected date range for the workout volume chart.
        var dateRange: ActivityDateRange = .month

        /// Weekly activity segments fetched and aggregated from HealthKit.
        /// `nil` when no data has been fetched yet.
        var weeklyData: [WeeklyActivitySegment]?

        /// Controls the chart drawing animation (Y values interpolation).
        var isChartAnimated: Bool = false

        // MARK: - Derived

        /// Total number of workouts across all weeks and activity types.
        var totalWorkouts: Int {
            guard let data = weeklyData else { return 0 }
            return data.reduce(0) { $0 + $1.count }
        }

        /// Total duration of all workouts in minutes.
        var totalDurationMinutes: Double {
            weeklyData?.reduce(0) { $0 + $1.durationMinutes } ?? 0
        }

        /// Average duration per workout in minutes.
        var averageDurationMinutes: Double {
            guard totalWorkouts > 0 else { return 0 }
            return totalDurationMinutes / Double(totalWorkouts)
        }
    }
}
