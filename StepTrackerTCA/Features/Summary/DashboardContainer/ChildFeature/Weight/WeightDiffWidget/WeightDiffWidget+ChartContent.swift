//
//  WeightDiffWidget+ChartContent.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 21/01/2025.
//

import Charts
import SwiftUI

extension WeightDiffWidgetView {
    
    func createRuleMark<Content: View>(with selectedHealthMetric: WeekdayChartData,
                                       annotationView: @escaping () -> Content
    ) -> some ChartContent {
        RuleMark(x: .value("Selected Data", selectedHealthMetric.date, unit: .day))
            .foregroundStyle(Color.secondary.opacity(0.3))
            .offset(y: -10)
            .annotation(position: .top,
                        spacing: 0,
                        overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) { annotationView() }
    }
    
    func createWeightDiffBarMark(with weightDiff: WeekdayChartData) -> some ChartContent {
        BarMark(
            x: .value("Date", weightDiff.date, unit: .day),
            y: .value("Weight Diff", weightDiff.value)
        )
        .foregroundStyle(weightDiff.value >= 0 ? Color.indigo.gradient : Color.mint.gradient)
    }
    
}
