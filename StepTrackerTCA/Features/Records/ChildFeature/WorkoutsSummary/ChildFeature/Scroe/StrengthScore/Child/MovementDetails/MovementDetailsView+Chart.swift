//
//  MovementDetailsView+Chart.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/03/2025.
//

import Charts
import SwiftUI

extension MovementDetailsView {
    
    func createPointMark(with data: WorkoutStrength) -> some ChartContent {
        PointMark(
            x: .value("Day", data.date, unit: .day),
            y: .value("Value", data.value)
        )
        .foregroundStyle(.green)
        .interpolationMethod(.catmullRom)
        .symbol(.circle)
    }
    
    func createGoalRuleMark(_ goal: String) -> some ChartContent {
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
    
}
