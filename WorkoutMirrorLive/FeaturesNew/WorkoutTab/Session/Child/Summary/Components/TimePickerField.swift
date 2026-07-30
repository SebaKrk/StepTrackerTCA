//
//  TimePickerField.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/07/2026.
//

import SwiftUI

/// Inline mm:ss wheels for a For Time score — replaces free-text time entry.
/// Minutes are capped by the WOD's time cap when present.
struct TimePickerField: View {

    // MARK: - Properties

    let minutes: Int
    let seconds: Int
    let maxMinutes: Int
    let onMinutes: (Int) -> Void
    let onSeconds: (Int) -> Void
    @Environment(\.summaryPalette) private var theme
    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            minutesWheel
            colon
            secondsWheel
        }
        .frame(maxWidth: .infinity)
        .background(fieldBackground)
    }

    // MARK: - Implementation

    private var minutesWheel: some View {
        wheel(
            values: Array(0...max(1, maxMinutes)),
            selection: minutes,
            label: String(localized: "min"),
            onChange: onMinutes
        )
        .padding(.vertical, 4)
    }

    private var secondsWheel: some View {
        wheel(
            values: Array(0...59),
            selection: seconds,
            label: String(localized: "sek"),
            onChange: onSeconds
        )
        .padding(.vertical, 4)
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: SummaryTheme.innerRadius)
            .fill(theme.cardInner)
            .overlay(
                RoundedRectangle(cornerRadius: SummaryTheme.innerRadius)
                    .stroke(theme.stroke, lineWidth: 1)
            )
    }

    private func wheel(
        values: [Int],
        selection: Int,
        label: String,
        onChange: @escaping (Int) -> Void
    ) -> some View {
        VStack(spacing: 0) {
            Picker(label, selection: Binding(get: { selection }, set: onChange)) {
                ForEach(values, id: \.self) { value in
                    Text(String(format: "%02d", value))
                        .font(.system(size: 20, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(theme.ink)
                        .tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 96)
            .clipped()

            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(theme.inkTertiary)
                .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity)
    }

    private var colon: some View {
        Text(":")
            .font(.system(size: 22, weight: .heavy))
            .foregroundStyle(theme.inkTertiary)
    }
}

// MARK: - Previews

#Preview("TimePickerField — 9:00 przy capie 11") {
    VStack {
        TimePickerField(
            minutes: 9,
            seconds: 0,
            maxMinutes: 11,
            onMinutes: { _ in },
            onSeconds: { _ in }
        )
    }
    .summaryCard()
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SummaryTheme.background)
}
