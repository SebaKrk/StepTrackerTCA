//
//  DashboardView+Chart.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 04/01/2025.
//

import Charts
import SwiftUI

extension DashboardView {

    @ViewBuilder
    var stepChart: some View {
        Chart {
            RuleMark(y: .value("Average", store.avgStepCount))
                .foregroundStyle(Color.secondary)
                .lineStyle(.init(lineWidth: 1, dash: [5]))

            ForEach(store.stepData) { steps in
                BarMark(
                    x: .value("Date", steps.date, unit: .day),
                    y: .value("Steps", steps.value)
                )
            }
        }
        .frame(height: 150)
        .foregroundStyle(.pink)
        .chartXAxis {
            AxisMarks {
                AxisValueLabel(format: .dateTime.month(.defaultDigits).day())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                    .foregroundStyle(Color.secondary.opacity(0.3))
                AxisValueLabel((value.as(Double.self) ?? 0).formatted(.number.notation(.compactName)))
            }
        }
    }
    
}
