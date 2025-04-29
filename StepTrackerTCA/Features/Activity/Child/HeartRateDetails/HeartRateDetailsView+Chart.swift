//
//  HeartRateDetailsView+Chart.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 27/04/2025.
//

import Charts
import SwiftUI

extension HeartRateDetailsView {
    
    func createBarMark(_ stats: HeartRateMetricsMinute) -> some ChartContent {
        BarMark(
            x: .value("Minute", stats.minute, unit: .minute),
            yStart: .value("HR min", stats.minHR),
            yEnd: .value("HR max", stats.maxHR)
        )
        .opacity(store.rawSelectedDate == nil || stats.minute == store.selectedHeartRateMetric?.minute ? 1.0 : 0.3)
    }
    
    func createRuleMark<Content: View>(with selectedDate:  Date,
                                       annotationView: @escaping () -> Content
    ) -> some ChartContent {
        RuleMark(x: .value("Selected Metric", selectedDate, unit: .minute))
            .foregroundStyle(Color.secondary.opacity(0.3))
            .offset(y: -10)
            .annotation(position: .leading,
                        spacing: 0,
                        overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) { annotationView() }
    }

    
}


//        .chartXVisibleDomain(length: 15 * 60)
//        .chartScrollableAxes(.horizontal)
//        .chartScrollTargetBehavior(
//            .valueAligned(
//                matching: .init(minute: 0),
//                majorAlignment: .matching(.init(minute: 1)))
//        )
//        .chartScrollPosition(x: $store.scrollPositionStart)


