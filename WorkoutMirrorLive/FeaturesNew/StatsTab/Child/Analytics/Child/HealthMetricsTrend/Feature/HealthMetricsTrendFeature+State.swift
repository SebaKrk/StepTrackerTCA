//
//  HealthMetricsTrendFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 17/04/2026.
//

import ComposableArchitecture
import SharedModels

extension HealthMetricsTrendFeature {

    @ObservableState
    struct State {

        /// Current subscription tier (shared across app).
        @Shared(.appStorage(.subscriptionTier))
        var subscriptionTier: SubscriptionTier = .basic

        /// Minimum subscription tier required to access this feature.
        let requiredTier: SubscriptionTier = .elite

        /// Current loading state of the chart.
        var viewState: ViewState = .loading

        /// Content state for subscription overlay.
        var contentState: ContentState = .loading

        /// Currently selected health metric (RHR, HRV, Sleep, Activity).
        var selectedMetric: HealthMetricType = .rhr

        /// Selected date range for the trend chart.
        var dateRange: ActivityDateRange = .month

        /// Per-metric data cache. Cleared on date range change or refresh.
        var cachedData: [HealthMetricType: [HistoricalDataPoint]] = [:]

        /// Daily activity segments for stacked bar chart (activity metric only).
        var activitySegments: [DailyActivitySegment]?

        /// Currently selected data point on the chart (tap interaction).
        var selectedDataPoint: HistoricalDataPoint?

        /// Controls the chart drawing animation (Y values interpolation).
        var isChartAnimated: Bool = false

        // MARK: - Derived

        /// Data points for the currently selected metric from cache.
        var currentData: [HistoricalDataPoint]? {
            guard let data = cachedData[selectedMetric], !data.isEmpty else { return nil }
            return data
        }

        /// Average value of the currently selected metric data.
        var average: Double? {
            guard let data = currentData else { return nil }
            return data.reduce(0.0) { $0 + $1.value } / Double(data.count)
        }

        /// 7-day rolling average of the currently selected metric data.
        var rollingAverage: [HistoricalDataPoint] {
            guard let data = currentData, data.count >= 2 else { return [] }
            let windowSize = 7
            return data.enumerated().map { index, point in
                let start = max(0, index - windowSize + 1)
                let window = data[start...index]
                let avg = window.reduce(0.0) { $0 + $1.value } / Double(window.count)
                return HistoricalDataPoint(date: point.date, value: avg)
            }
        }
    }
}
