//
//  StepWidget+ChartContent.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 21/01/2025.
//

import Charts
import SwiftUI

extension StepWidgetView {
    
    func createRuleMark<Content: View>(with selectedHealthMetric:  HealthData,
                                       annotationView: @escaping () -> Content
    ) -> some ChartContent {
        RuleMark(x: .value("Selected Metric", selectedHealthMetric.date, unit: .day))
            .foregroundStyle(Color.secondary.opacity(0.3))
            .offset(y: -10)
            .annotation(position: .top,
                        spacing: 0,
                        overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) { annotationView() }
    }
    
    func createStepRuleMark() -> some ChartContent {
        RuleMark(y: .value("Average", store.avgStepCount))
            .foregroundStyle(Color.secondary)
            .lineStyle(.init(lineWidth: 1, dash: [5]))
    }
    
    func createStepBarMark(for steps: HealthData) -> some ChartContent {
        BarMark(
            x: .value("Date", steps.date, unit: .day),
            y: .value("Steps", steps.value)
        )
        .opacity(store.rawSelectedDate == nil || steps.date == store.selectedHealthMetric?.date ? 1.0 : 0.3)
    }
    
}
