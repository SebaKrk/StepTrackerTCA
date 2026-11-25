//
//  RoundsAndRepsFields.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/07/2026.
//

import SwiftUI

/// Completed rounds plus the reps of the unfinished one.
///
/// Serves every block scored that way — a plain AMRAP and an attempt the cap cut
/// short — and only the title tells them apart. The amber "unfinished" treatment
/// lives in the score line and the status segment, not here.
struct RoundsAndRepsFields: View {

    // MARK: - Properties

    /// What the tiles are asking for; the caller words it per format.
    let title: String

    /// Whole rounds the athlete finished.
    let rounds: Int

    /// Reps of the round left unfinished.
    let extraReps: Int

    /// Called with the new round count.
    let onRounds: (Int) -> Void

    /// Called with the new rep count.
    let onExtraReps: (Int) -> Void

    /// What the first stepper counts; a fitness run counts stations.
    var roundsLabel = String(localized: "Completed rounds", bundle: .main)

    /// What the second stepper counts; an open ladder names the round in progress.
    var extraRepsLabel = String(localized: "Reps in round", bundle: .main)

    /// The second stepper; a fitness run asks for the partial work on the station itself.
    var showsExtraReps = true

    /// What the first stepper counts up to; nil where the plan sets no ceiling.
    var roundsTotal: Int?

    /// What the second stepper counts up to; nil where the plan sets no ceiling.
    var extraRepsTotal: Int?

    /// A larger step for the second stepper; nil where one rep at a time is enough.
    var extraRepsBigStep: Int?

    @Environment(\.summaryPalette) private var theme

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            titleLabel
            HStack(spacing: 10) {
                completedRoundsStepper
                if showsExtraReps {
                    extraRepsStepper
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.snappy, value: extraRepsBigStep)
        .animation(.snappy, value: extraRepsLabel)
        .animation(.snappy, value: extraRepsTotal)
    }

    // MARK: - Implementation

    private var titleLabel: some View {
        Text(title)
            .font(.system(size: 12.5, weight: .semibold))
            .foregroundStyle(theme.inkSecondary)
    }

    private var completedRoundsStepper: some View {
        stepperTile(
            label: roundsLabel,
            value: rounds,
            total: roundsTotal,
            bigStep: nil,
            onChange: onRounds
        )
    }

    private var extraRepsStepper: some View {
        stepperTile(
            label: extraRepsLabel,
            value: extraReps,
            total: extraRepsTotal,
            bigStep: extraRepsBigStep,
            onChange: onExtraReps
        )
    }

    private func stepperTile(
        label: String,
        value: Int,
        total: Int?,
        bigStep: Int?,
        onChange: @escaping (Int) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(0.6)
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundStyle(theme.inkTertiary)
                .contentTransition(.opacity)
            HStack(spacing: 8) {
                stepButton(systemName: "minus") { onChange(max(0, value - 1)) }
                Spacer(minLength: 0)
                valueLabel(value, of: total)
                Spacer(minLength: 0)
                stepButton(systemName: "plus") { onChange(value + 1) }
            }
            if let bigStep {
                HStack(spacing: 8) {
                    bigStepButton(title: "−\(bigStep)") { onChange(max(0, value - bigStep)) }
                    bigStepButton(title: "+\(bigStep)") { onChange(value + bigStep) }
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(theme.cardInner, in: .rect(cornerRadius: SummaryTheme.innerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: SummaryTheme.innerRadius)
                .stroke(theme.stroke, lineWidth: 1)
        )
    }

    private func valueLabel(_ value: Int, of total: Int?) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(verbatim: "\(value)")
                .font(.system(size: 24, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(theme.ink)
                .contentTransition(.numericText(value: Double(value)))
            if let total {
                Text(verbatim: "/ \(total)")
                    .font(.system(size: 12, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(theme.inkTertiary)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .animation(.snappy, value: value)
    }

    private func bigStepButton(title: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Text(verbatim: title)
                .font(.system(size: 12, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(theme.inkSecondary)
                .frame(maxWidth: .infinity, minHeight: 28)
                .background(Color.white.opacity(0.05), in: .rect(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.stroke, lineWidth: 1)
                )
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
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

#Preview("RoundsAndRepsFields — DNF i AMRAP (galeria 5)") {
    VStack(spacing: 16) {
        VStack {
            RoundsAndRepsFields(
                title: "How far did you get before the cap?",
                rounds: 4,
                extraReps: 12,
                onRounds: { _ in },
                onExtraReps: { _ in }
            )
        }
        .summaryCard()

        VStack {
            RoundsAndRepsFields(
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
