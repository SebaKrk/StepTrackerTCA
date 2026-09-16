//
//  StatusControl.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/07/2026.
//

import SwiftUI

/// Card-header status. Pill = display state (For Time without cap, EMOM/Tabata
/// after confirming). Segment = always-visible Completed/DNF switch (For Time
/// with a cap only); switching never clears drafts (rule R-b).
struct StatusControl: View {

    enum Mode {
        case pill(completed: Bool)
        case segment(status: WODScoringFeature.WodStatus, onChange: (WODScoringFeature.WodStatus) -> Void)
    }

    // MARK: - Properties

    let mode: Mode
    let accent: Color
    @Environment(\.summaryPalette) private var theme
    // MARK: - Body

    var body: some View {
        switch mode {
        case let .pill(completed):
            statusPill(completed: completed)
        case let .segment(status, onChange):
            segment(status: status, onChange: onChange)
        }
    }

    // MARK: - Pill

    @ViewBuilder
    private func statusPill(completed: Bool) -> some View {
        if completed {
            HStack(spacing: 6) {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .heavy))
                Text(completedTitle)
                    .lineLimit(1)
                    .fixedSize()
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(theme.onAccent)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(accent, in: .capsule)
        } else {
            Text(notFinishedTitle)
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

    // MARK: - Segment

    private func segment(
        status: WODScoringFeature.WodStatus,
        onChange: @escaping (WODScoringFeature.WodStatus) -> Void
    ) -> some View {
        HStack(spacing: 2) {
            segmentOption(
                title: completedTitle,
                isActive: status == .completed,
                activeColor: accent
            ) {
                onChange(.completed)
            }
            segmentOption(
                title: notFinishedTitle,
                isActive: status == .notFinished,
                activeColor: .orange
            ) {
                onChange(.notFinished)
            }
        }
        .padding(2)
        .background(theme.cardInner, in: .capsule)
        .overlay(Capsule().stroke(theme.stroke, lineWidth: 1))
    }

    private func segmentOption(
        title: String,
        isActive: Bool,
        activeColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            Text(title)
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

    // MARK: - Strings

    private var completedTitle: String {
        String(localized: "Completed")
    }

    private var notFinishedTitle: String {
        String(localized: "Not finished")
    }
}

// MARK: - Previews

#Preview("StatusControl — pigułki i segment (galeria 3)") {
    VStack(alignment: .leading, spacing: 16) {
        StatusControl(mode: .pill(completed: true), accent: SummaryTheme.mint)
        StatusControl(mode: .pill(completed: false), accent: SummaryTheme.mint)
        StatusControl(mode: .segment(status: .completed, onChange: { _ in }), accent: SummaryTheme.mint)
        StatusControl(mode: .segment(status: .notFinished, onChange: { _ in }), accent: SummaryTheme.mint)
    }
    .summaryCard()
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SummaryTheme.background)
}
