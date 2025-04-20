//
//  MovementDetailsView+Chart.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/03/2025.
//

import Charts
import SwiftUI

extension MovementDetailsView {
    
    func createPointMark(with data: WorkoutMeasurement) -> some ChartContent {
        PointMark(
            x: .value("Day", data.date, unit: .day),
            y: .value("Value", data.value)
        )
        .foregroundStyle(.green)
        .interpolationMethod(.catmullRom)
        .symbol(.circle)
    }
    
    func createGoalRuleMark(_ goal: Double) -> some ChartContent {
        RuleMark(y: .value("Goal", goal))
            .foregroundStyle(.pink)
            .lineStyle(.init(lineWidth: 1, dash: [5]))
            .annotation(alignment: .bottomLeading) {
                Text("Goal")
                    .bold()
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
    }
    
    func createGoalRuleMarkIntervals(start: Date, end: Date, value: Double) -> some ChartContent {
        RuleMark(
            xStart: .value("Start Date", start),
            xEnd: .value("End Date", end),
            y: .value("Goal", value)
        )
        .foregroundStyle(.pink)
        .lineStyle(.init(lineWidth: 1, dash: [5]))
    }
    
    func selectedPointMark<Content: View>(with selectedPoint: WorkoutMeasurement,
                                       annotationView: @escaping () -> Content
    ) -> some ChartContent {
        PointMark(x: .value("Selected Point", selectedPoint.date, unit: .day))
            .foregroundStyle(Color.secondary.opacity(0.3))
            .offset(y: -10)
            .annotation(position: .top,
                        spacing: 0,
                        overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                annotationView()
            }
    }
    
}
