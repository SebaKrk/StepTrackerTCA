//
//  StepPieWidget+ChartContent.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 21/01/2025.
//

import Charts
import SwiftUI

extension StepPieWidgetView {
    
    func createPieChart(for weekday: WeekdayChartData) -> some ChartContent {
        SectorMark(angle: .value("Average Steps", weekday.value),
                   innerRadius: .ratio(0.618),
                   outerRadius: store.selectedChartValue?.date.weekdayInt == weekday.date.weekdayInt ? 140 : 110,
                   angularInset: 1)
        .foregroundStyle(.pink.gradient)
        .cornerRadius(6)
        .opacity(store.selectedChartValue?.date.weekdayInt == weekday.date.weekdayInt ? 1.0 : 0.3)
    }
}
