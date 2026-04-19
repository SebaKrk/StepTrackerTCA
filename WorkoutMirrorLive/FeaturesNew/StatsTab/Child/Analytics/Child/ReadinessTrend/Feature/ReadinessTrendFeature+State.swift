//
//  ReadinessTrendFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 16/04/2026.
//

import ComposableArchitecture
import SharedModels

extension ReadinessTrendFeature {

    @ObservableState
    struct State {

        /// Current subscription tier (shared across app).
        @Shared(.appStorage(.subscriptionTier))
        var subscriptionTier: SubscriptionTier = .basic

        /// Minimum subscription tier required to access this feature.
        let requiredTier: SubscriptionTier = .pro

        /// Current loading state of the chart.
        var viewState: ViewState = .loading

        /// Content state for subscription overlay.
        var contentState: ContentState = .loading

        /// Selected date range for the readiness trend chart.
        var dateRange: ActivityDateRange = .twoWeeks

        /// Training readiness results fetched from the client.
        /// `nil` when no data has been fetched yet.
        var historyData: [TrainingReadinessResult]?

        /// Currently selected data point on the chart (tap interaction).
        var selectedDataPoint: TrainingReadinessResult?

        /// Controls the chart drawing animation (Y values interpolation).
        var isChartAnimated: Bool = false

        // MARK: - Derived

        /// Average readiness score across the displayed period.
        var averageScore: Int {
            guard let data = historyData, !data.isEmpty else { return 0 }
            let sum = data.reduce(0) { $0 + $1.overallScore }
            return sum / data.count
        }

        /// Number of days per readiness level in the displayed period.
        var daysPerLevel: [ReadinessLevel: Int] {
            guard let data = historyData else { return [:] }
            var counts: [ReadinessLevel: Int] = [:]
            for result in data {
                counts[result.readinessLevel, default: 0] += 1
            }
            return counts
        }
    }
}
