//
//  WeightTrendView+ChartContent.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 18/04/2026.
//

import SwiftUI

extension WeightTrendView {

    // MARK: - Annotation Popup

    func annotationPopup(value: String, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(.primary)
            Text(date.formatted(.dateTime.month(.abbreviated).day()))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .secondary.opacity(0.3), radius: 2, x: 2, y: 2)
        )
    }

    // MARK: - Y Domain

    func yDomain(for data: [WeightTrendFeature.WeightDataPoint]) -> ClosedRange<Double> {
        guard let minW = data.map(\.weight).min(),
              let maxW = data.map(\.weight).max() else {
            return 60...100
        }
        let padding = max((maxW - minW) * 0.15, 1.0)
        return (minW - padding)...(maxW + padding)
    }
}
