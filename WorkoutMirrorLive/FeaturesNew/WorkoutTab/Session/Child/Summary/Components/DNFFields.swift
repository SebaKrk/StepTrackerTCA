//
//  DNFFields.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/07/2026.
//

import SwiftUI

/// Rounds + reps stepper tiles. Serve two matrix rows: DNF capture
/// ("Dokąd doszedłeś przed upływem limitu?") and plain AMRAP scoring ("Wynik")
/// — only the title differs; the amber DNF semantics live in ScoreLine/segment.
struct DNFFields: View {

    // MARK: - Properties

    let title: String
    let rounds: Int
    let extraReps: Int
    let onRounds: (Int) -> Void
    let onExtraReps: (Int) -> Void
    @Environment(\.summaryPalette) private var theme
    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            titleLabel
            HStack(spacing: 10) {
                completedRoundsStepper
                extraRepsStepper
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Implementation

    private var titleLabel: some View {
        Text(title)
            .font(.system(size: 12.5, weight: .semibold))
            .foregroundStyle(theme.inkSecondary)
    }

    private var completedRoundsStepper: some View {
        stepperTile(
            label: String(localized: "Completed rounds"),
            value: rounds,
            onChange: onRounds
        )
    }

    private var extraRepsStepper: some View {
        stepperTile(
            label: String(localized: "Reps in round"),
            value: extraReps,
            onChange: onExtraReps
        )
    }

    private func stepperTile(
        label: String,
        value: Int,
        onChange: @escaping (Int) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(theme.inkTertiary)
            HStack(spacing: 8) {
                stepButton(systemName: "minus") { onChange(max(0, value - 1)) }
                Spacer(minLength: 0)
                Text("\(value)")
                    .font(.system(size: 24, weight: .heavy))
                    .monospacedDigit()
                    .foregroundStyle(theme.ink)
                Spacer(minLength: 0)
                stepButton(systemName: "plus") { onChange(value + 1) }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(theme.cardInner, in: .rect(cornerRadius: SummaryTheme.innerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: SummaryTheme.innerRadius)
                .stroke(theme.stroke, lineWidth: 1)
        )
    }

    private func stepButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(theme.inkSecondary)
                .frame(width: 26, height: 26)
                .background(Color.white.opacity(0.05), in: .rect(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.stroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("DNFFields — DNF i AMRAP (galeria 5)") {
    VStack(spacing: 16) {
        VStack {
            DNFFields(
                title: "How far did you get before the cap?",
                rounds: 4,
                extraReps: 12,
                onRounds: { _ in },
                onExtraReps: { _ in }
            )
        }
        .summaryCard()

        VStack {
            DNFFields(
                title: "Score",
                rounds: 6,
                extraReps: 14,
                onRounds: { _ in },
                onExtraReps: { _ in }
            )
        }
        .summaryCard()
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SummaryTheme.background)
}
