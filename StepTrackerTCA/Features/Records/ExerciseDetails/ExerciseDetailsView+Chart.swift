//
//  ExerciseDetailsView+Chart.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 18/02/2025.
//

import Charts
import SwiftUI

extension ExerciseDetailsView {
    
    func createAreaMark(with data: WeightLiftingMeasurement) -> some ChartContent {
        AreaMark(
            x: .value("Day", data.date, unit: .day),
            yStart: .value("Value", data.value),
            yEnd: .value("Min value", store.minValue)
            //y:  .value("Min value", data.value)
        )
        .foregroundStyle(Gradient(colors: [.green.opacity(0.5), .clear]))
        .interpolationMethod(.catmullRom)
    }
    
    func createWeightLineMark(with data: WeightLiftingMeasurement) -> some ChartContent {
        LineMark(
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
    
}
