//
//  ScoreLine.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/07/2026.
//

import SwiftUI

/// Result line of a card: empty slot (dashed frame + format hint),
/// filled typed result, or amber DNF (time cap). Editing has no variant here —
/// the inline editor renders its own fields in place of this line.
struct ScoreLine: View {

    enum Variant: Equatable {
        /// Dashed slot with a type-appropriate format hint ("mm:ss", "rundy + powtórzenia").
        case empty(hint: String)
        /// Frozen typed result, e.g. "9:00" + "limit 11:00"; `isPR` adds the yellow chip.
        case filled(value: String, detail: String?, isPR: Bool)
        /// Time-cap cutoff in amber, e.g. "11:00" + "· 4 rundy + 12 reps".
        case dnf(value: String, detail: String?)
    }

    // MARK: - Properties

    let kind: String
    let variant: Variant
    @Environment(\.summaryPalette) private var theme
    // MARK: - Body

    var body: some View {
        lineContent
    }

    // MARK: - Implementation

    private var lineContent: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            kindLabel
            valueContent
            Spacer(minLength: 0)
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 14)
        .background(fill, in: .rect(cornerRadius: SummaryTheme.innerRadius))
        .overlay(border)
    }

    private var kindLabel: some View {
        Text(kind)
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.8)
            .textCase(.uppercase)
            .foregroundStyle(theme.inkSecondary)
    }

    @ViewBuilder
    private var valueContent: some View {
        switch variant {
        case let .empty(hint):
            Text(hint)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(theme.inkTertiary)

        case let .filled(value, detail, isPR):
            valueText(value, color: theme.ink)
            detailText(detail)
            if isPR { prChip }

        case let .dnf(value, detail):
            valueText(value, color: .orange)
            detailText(detail)
        }
    }

    private func valueText(_ value: String, color: Color) -> some View {
        Text(value)
            .font(.system(size: 17, weight: .heavy))
            .monospacedDigit()
            .foregroundStyle(color)
    }

    @ViewBuilder
    private func detailText(_ detail: String?) -> some View {
        if let detail {
            Text(detail)
                .font(.system(size: 12))
                .foregroundStyle(theme.inkSecondary)
        }
    }

    private var prChip: some View {
        Text("PR")
            .font(.system(size: 10, weight: .heavy))
            .foregroundStyle(Color(red: 42 / 255, green: 26 / 255, blue: 0))
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(.yellow, in: .rect(cornerRadius: 6))
    }

    private var fill: Color {
        switch variant {
        case .empty: .clear
        case .filled: theme.cardInner
        case .dnf: Color.orange.opacity(0.08)
        }
    }

    @ViewBuilder
    private var border: some View {
        switch variant {
        case .empty:
            RoundedRectangle(cornerRadius: SummaryTheme.innerRadius)
                .stroke(
                    Color.white.opacity(0.14),
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                )
        case .filled:
            RoundedRectangle(cornerRadius: SummaryTheme.innerRadius)
                .stroke(theme.stroke, lineWidth: 1)
        case .dnf:
            RoundedRectangle(cornerRadius: SummaryTheme.innerRadius)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        }
    }
}

// MARK: - Previews

#Preview("ScoreLine — 4 warianty (makieta, galeria 4)") {
    VStack(spacing: 10) {
        ScoreLine(kind: "Score · For Time", variant: .empty(hint: "mm:ss"))
        ScoreLine(kind: "Score · For Time", variant: .filled(value: "9:00", detail: "limit 11:00", isPR: false))
        ScoreLine(kind: "Heaviest set", variant: .filled(value: "150 kg", detail: "× 2", isPR: true))
        ScoreLine(kind: "Score · Time cap", variant: .dnf(value: "11:00", detail: "· 4 rundy + 12 reps"))
    }
    .summaryCard()
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SummaryTheme.background)
}
