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
            if let selectedHealthMetric = store.selectedHealthMetric {
                RuleMark(x: .value("Selected Metric", selectedHealthMetric.date, unit: .day))
                    .foregroundStyle(Color.secondary.opacity(0.3))
                    .offset(y: -10)
                    .annotation(position: .top,
                                spacing: 0,
                                overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) { annotationView }
            }
            
            RuleMark(y: .value("Average", store.avgStepCount))
                .foregroundStyle(Color.secondary)
                .lineStyle(.init(lineWidth: 1, dash: [5]))
            
            ForEach(store.stepData) { steps in
                BarMark(
                    x: .value("Date", steps.date, unit: .day),
                    y: .value("Steps", steps.value)
                )
                .opacity(store.rawSelectedDate == nil || steps.date == store.selectedHealthMetric?.date ? 1.0 : 0.3)
            }
        }
        .frame(height: 200)
        .chartXSelection(value: $store.rawSelectedDate.animation(.easeInOut))
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
    
    @ViewBuilder
    var stepsPieChart: some View {
        Chart {
            ForEach(store.stepDataPerWeekDay) { weekday in
                SectorMark(angle: .value("Average Steps", weekday.value),
                           innerRadius: .ratio(0.618),
                           angularInset: 1)
                .foregroundStyle(.pink.gradient)
                .cornerRadius(6)
            }
        }
        .frame(height: 240)
    }
    
}
