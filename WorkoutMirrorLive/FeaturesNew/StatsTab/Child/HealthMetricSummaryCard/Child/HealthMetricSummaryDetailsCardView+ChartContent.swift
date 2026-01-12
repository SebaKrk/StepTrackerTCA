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
    
    // Tworzy pionową linię z adnotacją dla wybranego punktu
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
    
    // Zwraca kolor dla danego typu metryki
    func colorForMetric(_ metricType: HealthMetricType) -> Color {
        switch metricType {
        case .rhr: return .red
        case .hrv: return .green
        case .sleep: return .purple
        case .activity: return .orange
        }
    }
}
