//
//  HealthMetricSummaryDetailsCardView+ChartContent.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 11/01/2026.
//

import Charts
import SwiftUI
import SharedModels

extension HealthMetricSummaryDetailsCardView {

    func createRuleMark<Content: View>(
        with selectedPoint: HistoricalDataPoint,
        annotationView: @escaping () -> Content
    ) -> some ChartContent {
        RuleMark(x: .value("Selected Data", selectedPoint.date, unit: .day))
            .foregroundStyle(Color.secondary.opacity(0.3))
            .offset(y: -10)
            .annotation(
                position: .top,
                spacing: 0,
                overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
            ) {
                annotationView()
            }
    }
    
    // Tworzy punkt i linię dla danych historycznych
    func createLineMark(with point: HistoricalDataPoint, color: Color) -> some ChartContent {
        LineMark(
            x: .value("Date", point.date, unit: .day),
            y: .value("Value", point.value)
        )
        .foregroundStyle(color.gradient)
        .symbol(Circle())
    }
    
    // Tworzy poziomą linię referencyjną dla wartości bazowej
    func createBaselineRuleMark(baselineValue: Double) -> some ChartContent {
        RuleMark(y: .value("Baseline", baselineValue))
            .foregroundStyle(Color.secondary.opacity(0.5))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
    }
    
    // Tworzy poziomą linię dla średniej tygodniowej z adnotacją
    func createAverageRuleMark(averageValue: Double) -> some ChartContent {
        RuleMark(y: .value("Średnia", averageValue))
            .foregroundStyle(Color.primary.opacity(0.8))
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [3, 3]))
            .annotation(position: .top, alignment: .leading) {
                Text(averageValue, format: .number.precision(.fractionLength(1)))
                    .font(.caption2.bold())
                    .foregroundColor(.primary)
            }
    }
    
    // Zwraca kolor na podstawie wyniku (score)
    func colorForScore(_ score: Int, data: TrainingComponentScore) -> Color {
        let totalRange = data.maxScore - data.minScore
        let quarterRange = Double(totalRange) / 4.0
        
        let boundary1 = data.minScore + Int(quarterRange)
        let boundary2 = data.minScore + Int(quarterRange * 2)
        let boundary3 = data.minScore + Int(quarterRange * 3)
        
        if score <= boundary1 {
            return .red
        } else if score <= boundary2 {
            return .orange
        } else if score <= boundary3 {
            return .yellow
        } else {
            return .green
        }
    }
}
