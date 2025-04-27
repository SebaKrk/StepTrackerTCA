//
//  HeartRateDetailsView+Chart.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 27/04/2025.
//

import Charts
import SwiftUI

extension HeartRateDetailsView {
    
    @ViewBuilder
    func createChartView(_ hrData: [HeartRateMetricsMinute]) -> some View {
        Chart {
            ForEach(hrData, id: \.minute) { stats in
                BarMark(
                    x: .value("Minute", stats.minute, unit: .minute),
                    yStart: .value("HR min", stats.minHR),
                    yEnd: .value("HR max", stats.maxHR)
                )
            }
            .foregroundStyle(.pink.opacity(0.9))
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXAxis {
            AxisMarks(preset: .aligned, values: .automatic) { value in
                AxisValueLabel()
            }
        }
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
