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
        let range: ClosedRange<Double>
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
    
    /// The gauge behind the score, drawn from the same thresholds as its label.
    ///
    /// Was a quartile split of the range, which produced colours the status
    /// vocabulary does not contain — a yellow band under a mint label — and left
    /// the backdrop contradicting the text even once the pill was fixed.
    func metricSegments(for data: TrainingComponentScore) -> [MetricSegment] {
        let bands = data.statusBands

        return bands.enumerated().map { index, band in
            MetricSegment(
                range: band.range,
                color: band.status.color,
                cornerRadius: cornerRadius(at: index, of: bands.count)
            )
        }
    }

    /// Rounds only the ends of the gauge.
    private func cornerRadius(at index: Int, of count: Int) -> MetricSegment.CornerRadius {
        if index == 0 { return .bottom }
        if index == count - 1 { return .top }

        return MetricSegment.CornerRadius.none
    }
    
    @ChartContentBuilder
    func metricChart(for data: TrainingComponentScore) -> some ChartContent {
        ForEach(metricSegments(for: data), id: \.range.lowerBound) { segment in
            createVerticalSegment(segment: segment)
        }
        
        let clampedScore = max(data.minScore, min(data.maxScore, data.score))

        metricIndicator(clampedScore)
            .annotation(position: .overlay, alignment: .center) {
                metricLabel(value: data.score, color: data.status.color)
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
            y: .value("Score", Double(score))
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
