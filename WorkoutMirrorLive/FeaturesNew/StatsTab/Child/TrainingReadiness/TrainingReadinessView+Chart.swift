//
//  TrainingReadinessView+Chart.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 28/09/2025.
//

import Charts
import SwiftUI

extension TrainingReadinessView {
    
    struct ReadinessSegment {
        let range: ClosedRange<Int>
        let color: Color
        let cornerRadius: CornerRadius
        
        struct CornerRadius {
            let topLeading: CGFloat
            let bottomLeading: CGFloat
            let bottomTrailing: CGFloat
            let topTrailing: CGFloat
            
            static let none = CornerRadius(topLeading: 0, bottomLeading: 0, bottomTrailing: 0, topTrailing: 0)
            static let leading = CornerRadius(topLeading: 5, bottomLeading: 5, bottomTrailing: 0, topTrailing: 0)
            static let trailing = CornerRadius(topLeading: 0, bottomLeading: 0, bottomTrailing: 5, topTrailing: 5)
        }
    }
    
    var readinessSegments: [ReadinessSegment] {
        [
            ReadinessSegment(range: 0...40, color: .red, cornerRadius: .leading),
            ReadinessSegment(range: 40...55, color: .orange, cornerRadius: .none),
            ReadinessSegment(range: 55...70, color: .yellow, cornerRadius: .none),
            ReadinessSegment(range: 70...85, color: .mint, cornerRadius: .none),
            ReadinessSegment(range: 85...100, color: .green, cornerRadius: .trailing)
        ]
    }
    
    @ChartContentBuilder
    func readinessBackground() -> some ChartContent {
        ForEach(readinessSegments, id: \.range.lowerBound) { segment in
            createSegmentMark(segment: segment)
        }
    }
    
    @ChartContentBuilder
    private func createSegmentMark(segment: ReadinessSegment) -> some ChartContent {
        RectangleMark(
            xStart: .value("Start", segment.range.lowerBound),
            xEnd: .value("End", segment.range.upperBound),
            yStart: .value("Y", 0),
            yEnd: .value("Y", 1)
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
    func readinessIndicator(_ value: Int) -> some ChartContent {
        PointMark(
            x: .value("Current", value),
            y: .value("Y", 0.5)
        )
        .symbolSize(0)
    }
    
    @ViewBuilder
    func readinessLabel(value: Int, color: Color) -> some View {
        Text("\(value)")
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color)
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }
    
}
