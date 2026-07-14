//
//  HealthMetricsTrendFeature+Model.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 17/04/2026.
//

import SharedModels
import SwiftUI

extension HealthMetricsTrendFeature {

    /// Bundled response from metric data fetch.
    /// `activitySegments` is non-nil only for the `.activity` metric.
    struct MetricFetchResult: Equatable {
        let dataPoints: [HistoricalDataPoint]
        let activitySegments: [DailyActivitySegment]?
    }

    /// One segment = one activity type in one day.
    /// Multiple segments per day enable stacked bar chart.
    struct DailyActivitySegment: Identifiable, Equatable {
        var id: String { "\(date.timeIntervalSince1970)-\(activityName)" }
        let date: Date
        let activityName: String
        let activityColor: Color
        let kcal: Double
    }
}
