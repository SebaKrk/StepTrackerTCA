//
//  WeightTrendFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 16/04/2026.
//

import ComposableArchitecture
import SharedModels

extension WeightTrendFeature {

    @ObservableState
    struct State {

        /// Current loading state of the chart.
        var viewState: ViewState = .loading

        /// Selected date range for the weight trend chart.
        var dateRange: ActivityDateRange = .month

        /// Daily weight data points fetched from HealthKit.
        /// `nil` when no data has been fetched yet.
        var weightData: [WeightDataPoint]?

        /// Currently selected data point on the chart (tap interaction).
        var selectedDataPoint: WeightDataPoint?

        /// Controls the chart drawing animation (Y values interpolation).
        var isChartAnimated: Bool = false

        // MARK: - Derived

        /// Weight change over the displayed period (last - first).
        var weightChange: Double? {
            guard let data = weightData,
                  let first = data.first,
                  let last = data.last,
                  data.count > 1 else { return nil }
            return last.weight - first.weight
        }

        /// Current (most recent) weight value.
        var currentWeight: Double? {
            weightData?.last?.weight
        }
    }
}
