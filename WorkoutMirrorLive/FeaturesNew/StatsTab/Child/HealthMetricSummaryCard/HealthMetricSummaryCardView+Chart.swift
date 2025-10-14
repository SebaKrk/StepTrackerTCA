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
        let midNegative = min / 2
        let midPositive = max / 2
        
        return [
            // Bardzo zły zakres (dół)
            MetricSegment(range: min...midNegative, color: .red, cornerRadius: .bottom),
            // Średnio zły
            MetricSegment(range: midNegative...0, color: .orange, cornerRadius: .none),
            // Neutralny/dobry
            MetricSegment(range: 0...midPositive, color: .yellow, cornerRadius: .none),
            // Bardzo dobry (góra)
            MetricSegment(range: midPositive...max, color: .green, cornerRadius: .top)
        ]
    }
    
    func colorForScore(_ score: Int, data: TrainingComponentScore) -> Color {
        let midNegative = data.minScore / 2
        let midPositive = data.maxScore / 2
        
        if score <= midNegative {
            return .red       // score <= -5 dla Activity
        } else if score < 0 {
            return .orange    // -4 <= score <= -1 dla Activity
        } else if score < midPositive {
            return .yellow    // 0 <= score <= 1 dla Activity
        } else {
            return .green     // score >= 2 dla Activity
        }
    }
    
    @ChartContentBuilder
    func metricChart(for data: TrainingComponentScore) -> some ChartContent {
        ForEach(metricSegments(for: data), id: \.range.lowerBound) { segment in
            createVerticalSegment(segment: segment)
        }
        
        metricIndicator(data.score)
            .annotation(position: .top, alignment: .center) {
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
