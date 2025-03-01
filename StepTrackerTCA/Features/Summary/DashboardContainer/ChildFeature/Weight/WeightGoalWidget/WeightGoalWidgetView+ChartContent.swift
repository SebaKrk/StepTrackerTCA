//
//  WeightGoalWidgetView+Chart.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 21/01/2025.
//

import Charts
import SwiftUI

extension WeightGoalWidgetView {
    
    func createRuleMark<Content: View>(with selectedHealthMetric: HealthData,
                                       annotationView: @escaping () -> Content
    ) -> some ChartContent {
        RuleMark(x: .value("Selected Metric", selectedHealthMetric.date, unit: .day))
            .foregroundStyle(Color.secondary.opacity(0.3))
            .offset(y: -10)
            .annotation(position: .top,
                        spacing: 0,
                        overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                annotationView()
            }
    }
    
    func createGoalRuleMark(_ weightGoal: Double) -> some ChartContent {
        RuleMark(y: .value("Goal", weightGoal))
            .foregroundStyle(.mint)
            .lineStyle(.init(lineWidth: 1, dash: [5]))
            .annotation(alignment: .bottomLeading) {
                Text("Weight goal")
                    .bold()
                    .foregroundStyle(.mint)
                    .font(.caption)
            }
    }
    
    func createWeightAreaMark(with weight: HealthData) -> some ChartContent {
        AreaMark(
            x: .value("Day", weight.date, unit: .day),
            yStart: .value("Value", weight.value),
            yEnd: .value("Min value", store.weightMinValue)
        )
        .foregroundStyle(Gradient(colors: [.indigo.opacity(0.5), .clear]))
        .interpolationMethod(.catmullRom)
    }
    
    func createWeightLineMark(with weight: HealthData) -> some ChartContent {
        LineMark(
            x: .value("Day", weight.date, unit: .day),
            y: .value("Value", weight.value)
        )
        .foregroundStyle(.indigo)
        .interpolationMethod(.catmullRom)
        .symbol(.circle)
    }
    
}
