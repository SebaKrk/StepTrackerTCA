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

    /// The value under the scrubber, in the same opaque container as the health metrics trend.
    func annotationPopup(score: Int, level: ReadinessLevel) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(score)")
                .font(.caption.bold())
                .foregroundStyle(.primary)

            Text(level.title)
                .font(.caption2)
                .foregroundStyle(level.color)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .secondary.opacity(0.3), radius: 2, x: 2, y: 2)
        )
    }
}
