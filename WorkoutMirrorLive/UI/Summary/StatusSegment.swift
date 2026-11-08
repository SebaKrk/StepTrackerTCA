//
//  StatusSegment.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 08/11/2026.
//

import SwiftUI

/// A card header's live choice between completed and not finished.
///
/// Switching never clears the drafts beside the result (rule R-b).
struct StatusSegment: View {

    // MARK: - Properties

    /// The option currently selected.
    let status: WODScoringFeature.WodStatus

    /// The section's accent, marking the completed option.
    let accent: Color

    /// Reports the option the athlete picked.
    let onChange: (WODScoringFeature.WodStatus) -> Void

    /// Colors of the surrounding Summary section.
    @Environment(\.summaryPalette) private var theme

    // MARK: - Body

    var body: some View {
        HStack(spacing: 2) {
            option(.completed, activeColor: accent)
            option(.notFinished, activeColor: .orange)
        }
        .padding(2)
        .background(theme.cardInner, in: .capsule)
        .overlay(Capsule().stroke(theme.stroke, lineWidth: 1))
    }

    // MARK: - Implementation

    private func option(
        _ option: WODScoringFeature.WodStatus,
        activeColor: Color
    ) -> some View {
        let isActive = status == option
        return Button {
            onChange(option)
        } label: {
            Text(option.title)
                .font(.system(size: 11, weight: .bold))
                .lineLimit(1)
                .fixedSize()
                .foregroundStyle(isActive ? theme.onAccent : theme.inkSecondary)
                .padding(.horizontal, 11)
                .padding(.vertical, 5)
                .background(isActive ? activeColor : .clear, in: .capsule)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("StatusSegment — wybór ukończenia") {
    VStack(alignment: .leading, spacing: 16) {
        StatusSegment(status: .completed, accent: SummaryTheme.mint, onChange: { _ in })
        StatusSegment(status: .notFinished, accent: SummaryTheme.mint, onChange: { _ in })
    }
    .summaryCard()
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SummaryTheme.background)
}
