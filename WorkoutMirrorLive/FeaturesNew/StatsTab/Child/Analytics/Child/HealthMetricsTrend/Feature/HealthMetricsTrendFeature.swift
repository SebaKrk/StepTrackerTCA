//
//  HealthMetricsTrendFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 17/04/2026.
//

import ComposableArchitecture
import Foundation
import HealthHub
import HealthKit
import SharedModels
import SwiftUI

/// Feature displaying detailed health metric trends over time.
///
/// Supports four metrics via a pill picker: RHR, HRV, Sleep, Activity.
/// - RHR / HRV -> line chart with 7-day rolling average
/// - Sleep -> bar chart with threshold-based color coding
/// - Activity -> stacked bar chart grouped by workout type + legend
///
/// Data is cached per metric in `cachedData`. Activity additionally caches
/// `activitySegments` for the stacked chart (cleared together with `cachedData`).
/// Requires Elite subscription tier.
@Reducer
struct HealthMetricsTrendFeature {

    // MARK: - Dependencies

    @Dependency(\.healthMetricHistoryClient) var healthMetricHistoryClient
    @Dependency(\.activityManager) var activityManager

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

                // MARK: - Internal

            case .internal(.fetchData):
                state.viewState = .loading
                state.isChartAnimated = false
                let metric = state.selectedMetric
                let days = state.dateRange.rawValue
                return .run { [healthMetricHistoryClient, activityManager] send in
                    await send(.internal(.dataResponse(
                        Result {
                            if metric == .activity {
                                // Single source of truth: this chart is "workout calories
                                // per day, broken down by type". Deriving dataPoints from the
                                // same segments keeps the average line, Y-axis and selection
                                // tooltip consistent with the visible bar heights — and drops
                                // the redundant whole-day activeEnergyBurned query.
                                let workouts = try await activityManager.fetchWorkouts(for: days, sortBy: .newestFirst)
                                let segments = HealthMetricsTrendFeature.aggregateDaily(workouts: workouts, days: days)
                                let dataPoints = HealthMetricsTrendFeature.dailyTotals(from: segments)
                                return MetricFetchResult(dataPoints: dataPoints, activitySegments: segments)
                            } else {
                                let dataPoints = try await healthMetricHistoryClient.fetchHistory(metric, days)
                                return MetricFetchResult(dataPoints: dataPoints, activitySegments: nil)
                            }
                        }
                    )))
                }

            case let .internal(.dataResponse(.success(result))):
                state.cachedData[state.selectedMetric] = result.dataPoints
                if let segments = result.activitySegments {
                    state.activitySegments = segments
                }
                state.viewState = .success
                state.contentState = .ready(state.subscriptionTier)
                return .run { send in
                    try? await Task.sleep(for: .milliseconds(50))
                    await send(.internal(.revealChart))
                }

            case .internal(.dataResponse(.failure)):
                state.viewState = .failed
                state.contentState = .noData
                return .none

            case .internal(.revealChart):
                state.isChartAnimated = true
                return .none

                // MARK: - View

            case .view(.viewDidAppear):
                guard state.cachedData[state.selectedMetric] == nil else { return .none }
                return .send(.internal(.fetchData))

            case .view(.refresh):
                state.cachedData = [:]
                state.activitySegments = nil
                state.selectedDataPoint = nil
                return .send(.internal(.fetchData))

            case let .view(.metricSelected(metric)):
                guard metric != state.selectedMetric else { return .none }
                state.selectedMetric = metric
                state.selectedDataPoint = nil
                guard state.cachedData[metric] == nil else {
                    return .none
                }
                return .send(.internal(.fetchData))

            case let .view(.dateRangeChanged(range)):
                state.dateRange = range
                state.cachedData = [:]
                state.activitySegments = nil
                state.selectedDataPoint = nil
                return .send(.internal(.fetchData))

            case let .view(.dataPointSelected(point)):
                state.selectedDataPoint = point
                return .none
            }
        }
    }
}

// MARK: - Daily Aggregation

extension HealthMetricsTrendFeature {

    /// Aggregates raw workouts into daily activity segments grouped by type.
    static func aggregateDaily(workouts: [HKWorkout], days: Int) -> [DailyActivitySegment] {
        let calendar = Calendar.current
        let now = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: now) else { return [] }

        var buckets: [Date: [HKWorkoutActivityType: Double]] = [:]

        for workout in workouts {
            guard workout.startDate >= startDate else { continue }
            let dayStart = calendar.startOfDay(for: workout.startDate)
            let type = workout.workoutActivityType
            let kcal = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
            buckets[dayStart, default: [:]][type, default: 0] += kcal
        }

        return buckets
            .sorted { $0.key < $1.key }
            .flatMap { date, activities in
                activities
                    .sorted { $0.key.rawValue < $1.key.rawValue }
                    .map { type, kcal in
                        DailyActivitySegment(
                            date: date,
                            activityName: type.name,
                            activityColor: type.color,
                            kcal: kcal
                        )
                    }
            }
    }

    /// Per-day totals derived from the stacked segments — the single source for the
    /// activity chart's average, Y-axis scale and selection tooltip, so they all
    /// agree with the visible bar heights (the sum of that day's segments).
    static func dailyTotals(from segments: [DailyActivitySegment]) -> [HistoricalDataPoint] {
        Dictionary(grouping: segments, by: \.date)
            .map { date, day in
                HistoricalDataPoint(date: date, value: day.reduce(0) { $0 + $1.kcal })
            }
            .sorted { $0.date < $1.date }
    }
}
