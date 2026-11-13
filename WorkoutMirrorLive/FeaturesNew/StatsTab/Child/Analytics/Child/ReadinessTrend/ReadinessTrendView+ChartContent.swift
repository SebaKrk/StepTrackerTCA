//
//  ReadinessTrendView+ChartContent.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 18/04/2026.
//

import SharedModels
import SwiftUI

extension ReadinessTrendView {

    // MARK: - Annotation Popup

    /// The value under the scrubber.
    ///
    /// On material rather than `secondarySystemBackground`: the chart sits on a
    /// tinted wash over a dark card, and a flat fill of that colour came out all
    /// but invisible. The level keeps its own colour here, so the popup names the
    /// same thing the point under it already shows.
    func annotationPopup(score: Int, level: ReadinessLevel) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(score)")
                .font(.caption.bold())
                .foregroundStyle(.primary)

            Text(level.title)
                .font(.caption2)
                .foregroundStyle(level.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(level.color.opacity(0.5), lineWidth: 0.5)
        )
    }
}
