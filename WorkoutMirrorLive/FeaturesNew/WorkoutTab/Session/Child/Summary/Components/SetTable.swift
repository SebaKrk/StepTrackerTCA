//
//  SetTable.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/07/2026.
//

import SharedModels
import SwiftUI

/// Strength set table (Seria | Powt. | kg). Read-only: the heaviest set is
/// highlighted in the accent (+ yellow PR chip). Editing: reps/kg cells become
/// numeric fields writing out through closures — no local state.
struct SetTable: View {

    // MARK: - Properties

    let sets: [SetEntry]
    let isEditing: Bool
    let accent: Color
    let isPR: Bool
    let onReps: (_ setIndex: Int, _ text: String) -> Void
    let onWeight: (_ setIndex: Int, _ text: String) -> Void
    @Environment(\.summaryPalette) private var theme
    // MARK: - Body

    var body: some View {
        tableContent
    }

    // MARK: - Implementation

    private var tableContent: some View {
        VStack(spacing: 0) {
            headerRow
            ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                setRow(index: index, set: set)
            }
        }
        .background(theme.card, in: .rect(cornerRadius: SummaryTheme.innerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: SummaryTheme.innerRadius)
                .stroke(theme.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: SummaryTheme.innerRadius))
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            headerCell(String(localized: "Seria"), width: 52, alignment: .leading)
            headerCell(String(localized: "Powt."), alignment: .leading)
            headerCell("kg", alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.03))
    }

    private func setRow(index: Int, set: SetEntry) -> some View {
        let isTop = isTopSet(index: index)
        return HStack(spacing: 0) {
            Text("\(index + 1)")
                .font(.system(size: 14, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(isTop ? accent : theme.inkTertiary)
                .frame(width: 52, alignment: .leading)
            repsCell(index: index, set: set, isTop: isTop)
            weightCell(index: index, set: set, isTop: isTop)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(isTop ? accent.opacity(0.14) : .clear)
        .overlay(alignment: .top) {
            if index > 0 {
                Divider().background(Color.white.opacity(0.05))
            }
        }
    }

    // MARK: - Cells

    @ViewBuilder
    private func repsCell(index: Int, set: SetEntry, isTop: Bool) -> some View {
        if isEditing {
            numericField(
                placeholder: String(localized: "Powt."),
                text: "\(set.reps)",
                keyboard: .numberPad,
                alignment: .leading
            ) { onReps(index, $0) }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text("\(set.reps)")
                .font(.system(size: 14, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(isTop ? accent : theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func weightCell(index: Int, set: SetEntry, isTop: Bool) -> some View {
        if isEditing {
            numericField(
                placeholder: "kg",
                text: set.weight.map { formatWeight($0) } ?? "",
                keyboard: .decimalPad,
                alignment: .trailing
            ) { onWeight(index, $0) }
            .frame(maxWidth: .infinity, alignment: .trailing)
        } else {
            HStack(spacing: 6) {
                Text(set.weight.map { formatWeight($0) } ?? "—")
                    .font(.system(size: 14, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(isTop ? accent : theme.ink)
                if isTop && isPR { prChip }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private func numericField(
        placeholder: String,
        text: String,
        keyboard: UIKeyboardType,
        alignment: TextAlignment,
        onChange: @escaping (String) -> Void
    ) -> some View {
        TextField(
            placeholder,
            text: Binding(get: { text == "0" ? "" : text }, set: onChange)
        )
        .keyboardType(keyboard)
        .multilineTextAlignment(alignment)
        .font(.system(size: 14, weight: .semibold))
        .monospacedDigit()
        .foregroundStyle(theme.ink)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .frame(maxWidth: 76)
        .background(Color.white.opacity(0.06), in: .rect(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.stroke, lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private func headerCell(_ title: String, width: CGFloat? = nil, alignment: Alignment) -> some View {
        Text(title)
            .font(.system(size: 10.5, weight: .semibold))
            .tracking(0.6)
            .textCase(.uppercase)
            .foregroundStyle(theme.inkTertiary)
            .frame(width: width)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: alignment)
    }

    /// Heaviest set wins; ties resolve to the first occurrence.
    private func isTopSet(index: Int) -> Bool {
        guard let maxWeight = sets.compactMap(\.weight).max(), maxWeight > 0 else { return false }
        return sets.firstIndex { $0.weight == maxWeight } == index
    }

    private func formatWeight(_ weight: Double) -> String {
        weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(weight))
            : String(format: "%.1f", weight)
    }

    private var prChip: some View {
        Text("PR")
            .font(.system(size: 10, weight: .heavy))
            .foregroundStyle(Color(red: 42 / 255, green: 26 / 255, blue: 0))
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(.yellow, in: .rect(cornerRadius: 6))
    }
}

// MARK: - Previews

#Preview("SetTable — read-only + edycja (galeria 6)") {
    VStack(spacing: 16) {
        SetTable(
            sets: [
                SetEntry(reps: 2, weight: 145),
                SetEntry(reps: 2, weight: 150),
                SetEntry(reps: 2, weight: 147),
            ],
            isEditing: false,
            accent: SummaryTheme.mint,
            isPR: true,
            onReps: { _, _ in },
            onWeight: { _, _ in }
        )
        SetTable(
            sets: [
                SetEntry(reps: 2, weight: 145),
                SetEntry(reps: 2, weight: 150),
                SetEntry(reps: 0, weight: nil),
            ],
            isEditing: true,
            accent: SummaryTheme.mint,
            isPR: false,
            onReps: { _, _ in },
            onWeight: { _, _ in }
        )
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SummaryTheme.background)
}
