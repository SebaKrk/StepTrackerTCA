//
//  WorkoutVolumeFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 16/04/2026.
//

import ComposableArchitecture
import Foundation
import HealthHub
import HealthKit
import SharedModels
import SwiftUI

/// Feature displaying weekly workout volume as a stacked bar chart.
///
/// Fetches workouts from HealthKit via `ActivityManager`, aggregates them
/// by week and activity type, and displays duration in a stacked bar chart.
@Reducer
struct WorkoutVolumeFeature {

    // MARK: - Dependency

    @Dependency(\.activityManager) var activityManager

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

                // MARK: - Internal

            case .internal(.fetchData):
                state.viewState = .loading
                state.isChartAnimated = false
                let days = state.dateRange.rawValue
                return .run { [activityManager] send in
                    await send(.internal(.dataResponse(
                        Result {
                            let workouts = try await activityManager.fetchWorkouts(for: days, sortBy: .newestFirst)
                            return WorkoutVolumeFeature.aggregateWeekly(workouts: workouts, days: days)
                        }
                    )))
                }

            case let .internal(.dataResponse(.success(data))):
                state.weeklyData = data
                state.viewState = .success
                return .run { send in
                    try? await Task.sleep(for: .milliseconds(50))
                    await send(.internal(.revealChart))
                }

            case .internal(.dataResponse(.failure)):
                state.viewState = .failed
                return .none

            case .internal(.revealChart):
                state.isChartAnimated = true
                return .none

                // MARK: - View

            case .view(.viewDidAppear):
                guard state.weeklyData == nil else {
                    return .none
                }
                return .send(.internal(.fetchData))

            case .view(.refresh):
                return .send(.internal(.fetchData))

            case let .view(.dateRangeChanged(range)):
                state.dateRange = range
                return .send(.internal(.fetchData))
            }
        }
    }
}

// MARK: - Aggregation

extension WorkoutVolumeFeature {

    /// Aggregates raw workouts into weekly activity segments grouped by type.
    static func aggregateWeekly(workouts: [HKWorkout], days: Int) -> [WeeklyActivitySegment] {
        let calendar = Calendar.current
        let now = Date()

        guard let startDate = calendar.date(byAdding: .day, value: -days, to: now) else {
            return []
        }

        var buckets: [Date: [HKWorkoutActivityType: (duration: Double, count: Int)]] = [:]

        var weekCursor = calendar.dateInterval(of: .weekOfYear, for: startDate)?.start ?? startDate
        let endWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now

        while weekCursor <= endWeek {
            buckets[weekCursor] = [:]
            if let next = calendar.date(byAdding: .weekOfYear, value: 1, to: weekCursor) {
                weekCursor = next
            } else {
                break
            }
        }

        for workout in workouts {
            guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: workout.startDate)?.start else {
                continue
            }
            let type = workout.workoutActivityType
            let existing = buckets[weekStart]?[type] ?? (0, 0)
            let minutes = workout.duration / 60.0
            buckets[weekStart, default: [:]][type] = (
                existing.duration + minutes,
                existing.count + 1
            )
        }

        return buckets
            .sorted { $0.key < $1.key }
            .flatMap { weekStart, activities in
                activities
                    .sorted { $0.key.rawValue < $1.key.rawValue }
                    .map { type, data in
                        WeeklyActivitySegment(
                            weekStart: weekStart,
                            activityName: type.name,
                            activityColor: type.color,
                            durationMinutes: data.duration,
                            count: data.count
                        )
                    }
            }
    }
}
