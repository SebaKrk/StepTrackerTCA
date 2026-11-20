//
//  StatusPill.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 08/11/2026.
//

import SwiftUI

/// A card header's frozen verdict — the result is in and no longer up for choice.
struct StatusPill: View {

    // MARK: - Properties

    /// The verdict this card settled on.
    let status: WODScoringFeature.WodStatus

    /// The section's accent, filling the pill when the work was completed.
    let accent: Color

    /// Colors of the surrounding Summary section.
    @Environment(\.summaryPalette) private var theme

    // MARK: - Body

    var body: some View {
        switch status {
        case .completed:
            completedPill
        case .notFinished:
            notFinishedPill
        }
    }

    // MARK: - Implementation

    private var completedPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .heavy))
            Text(status.title)
                .lineLimit(1)
                .fixedSize()
        }
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(theme.onAccent)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(accent, in: .capsule)
    }

    private var notFinishedPill: some View {
        Text(status.title)
            .font(.system(size: 12, weight: .bold))
            .lineLimit(1)
            .fixedSize()
            .foregroundStyle(theme.inkSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.05), in: .capsule)
            .overlay(Capsule().stroke(theme.stroke, lineWidth: 1))
    }
}

// MARK: - Previews

#Preview("StatusPill — ukończony i nieukończony") {
    VStack(alignment: .leading, spacing: 16) {
        StatusPill(status: .completed, accent: SummaryTheme.mint)
        StatusPill(status: .notFinished, accent: SummaryTheme.mint)
    }
    .summaryCard()
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SummaryTheme.background)
}
