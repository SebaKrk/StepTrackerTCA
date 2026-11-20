//
//  HealthMetricsTrendFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 17/04/2026.
//

import ComposableArchitecture
import SharedModels

extension HealthMetricsTrendFeature {

    @CasePathable
    enum Action: ViewAction {

        case `internal`(Internal)

        enum Internal {
            /// Triggers fetching health metric data (and optionally workout segments for activity).
            case fetchData

            /// Receives the bundled result of the metric data fetch.
            case dataResponse(Result<MetricFetchResult, Error>)

            /// Triggers the chart drawing animation after a short delay.
            case revealChart
        }

        case view(View)

        enum View {
            /// Triggered when the view appears on screen.
            case viewDidAppear

            /// Triggered by pull-to-refresh.
            case refresh

            /// Triggered when user selects a different health metric from the pill picker.
            case metricSelected(HealthMetricType)

            /// Triggered when user changes the date range selector.
            case dateRangeChanged(ActivityDateRange)

            /// Triggered when user taps a data point on the chart.
            case dataPointSelected(HistoricalDataPoint?)

            /// Triggered when the unlock button on the locked chart is tapped.
            case unlockButtonTapped
        }

        case delegate(Delegate)

        enum Delegate {

            /// Asks the parent to present the offer of Pro.
            case unlockRequested
        }
    }
}
