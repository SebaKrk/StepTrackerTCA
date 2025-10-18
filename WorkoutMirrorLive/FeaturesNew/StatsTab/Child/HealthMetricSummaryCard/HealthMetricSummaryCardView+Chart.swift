//
//  MetricSegment.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 14/10/2025.
//

import Charts
import SwiftUI
import SharedModels

extension HealthMetricSummaryCardView {
    
    struct MetricSegment {
        let range: ClosedRange<Int>
        let color: Color
        let cornerRadius: CornerRadius
        
        struct CornerRadius {
            let topLeading: CGFloat
            let bottomLeading: CGFloat
            let bottomTrailing: CGFloat
            let topTrailing: CGFloat
            
            static let none = CornerRadius(topLeading: 0, bottomLeading: 0, bottomTrailing: 0, topTrailing: 0)
            static let top = CornerRadius(topLeading: 5, bottomLeading: 0, bottomTrailing: 0, topTrailing: 5)
            static let bottom = CornerRadius(topLeading: 0, bottomLeading: 5, bottomTrailing: 5, topTrailing: 0)
        }
    }
    
    func metricSegments(for data: TrainingComponentScore) -> [MetricSegment] {
        let min = data.minScore
        let max = data.maxScore
        let totalRange = max - min
        let quarterRange = Double(totalRange) / 4.0
        
        let boundary1 = min + Int(quarterRange)
        let boundary2 = min + Int(quarterRange * 2)
        let boundary3 = min + Int(quarterRange * 3)
        
        return [
            MetricSegment(range: min...boundary1, color: .red, cornerRadius: .bottom),
            MetricSegment(range: boundary1...boundary2, color: .orange, cornerRadius: .none),
            MetricSegment(range: boundary2...boundary3, color: .yellow, cornerRadius: .none),
            MetricSegment(range: boundary3...max, color: .green, cornerRadius: .top)
        ]
    }
    
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
    
    @ChartContentBuilder
    func metricChart(for data: TrainingComponentScore) -> some ChartContent {
        ForEach(metricSegments(for: data), id: \.range.lowerBound) { segment in
            createVerticalSegment(segment: segment)
        }
        
        metricIndicator(data.score)
            .annotation(position: .overlay, alignment: .center) {
                metricLabel(value: data.score, color: colorForScore(data.score, data: data))
            }
    }
    
    @ChartContentBuilder
    private func createVerticalSegment(segment: MetricSegment) -> some ChartContent {
        RectangleMark(
            xStart: .value("X", 0),
            xEnd: .value("X", 1),
            yStart: .value("Start", segment.range.lowerBound),
            yEnd: .value("End", segment.range.upperBound)
        )
        .foregroundStyle(segment.color.opacity(0.3))
        .clipShape(
            .rect(
                topLeadingRadius: segment.cornerRadius.topLeading,
                bottomLeadingRadius: segment.cornerRadius.bottomLeading,
                bottomTrailingRadius: segment.cornerRadius.bottomTrailing,
                topTrailingRadius: segment.cornerRadius.topTrailing
            )
        )
    }
    
    @ChartContentBuilder
    func metricIndicator(_ score: Int) -> some ChartContent {
        PointMark(
            x: .value("X", 0.5),
            y: .value("Score", score)
        )
        .symbolSize(0)
    }
    
    @ViewBuilder
    func metricLabel(value: Int, color: Color) -> some View {
        Text("\(value)")
            .font(.caption)
            .fontWeight(.bold)
            .frame(minWidth: 30)
            .background(color)
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }
    
}
