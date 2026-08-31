//
//  ExerciseList.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/07/2026.
//

import SwiftUI

/// WOD ladder: bold rep prefix + exercise name (+ scaling line), right column
/// shows the item's status (— / ✓ / weight+RX / partial). A DNF card inserts
/// an amber "limit" separator; items below it render muted.
struct ExerciseList: View {

    struct Row {
        let repPrefix: String?
        let name: String
        let scaling: String?
        let actual: Actual
        var isMuted: Bool = false
    }

    enum Actual {
        case none
        case done
        case weight(String, rx: Bool)
        case partial(done: Int, total: Int)
    }

    enum Item {
        case exercise(Row)
        case limit(text: String)
    }

    // MARK: - Properties

    let items: [Item]
    let accent: Color
    @Environment(\.summaryPalette) private var theme
    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                switch item {
                case let .exercise(row):
                    exerciseRow(row, showsDivider: index > 0)
                case let .limit(text):
                    limitSeparator(text)
                }
            }
        }
    }

    // MARK: - Implementation

    private func exerciseRow(_ row: Row, showsDivider: Bool) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                nameLine(row)
                scalingLine(row)
            }
            Spacer(minLength: 8)
            actualView(row)
        }
        .padding(.vertical, 9)
        .overlay(alignment: .top) {
            if showsDivider { rowDivider }
        }
    }

    private var rowDivider: some View {
        Divider().background(Color.white.opacity(0.05))
    }

    private func nameLine(_ row: Row) -> some View {
        HStack(spacing: 6) {
            if let repPrefix = row.repPrefix {
                Text(repPrefix)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(theme.inkSecondary)
            }
            Text(row.name)
                .font(.system(size: 14, weight: row.isMuted ? .medium : .semibold))
                .foregroundStyle(row.isMuted ? theme.inkSecondary : theme.ink)
        }
    }

    @ViewBuilder
    private func scalingLine(_ row: Row) -> some View {
        if let scaling = row.scaling {
            Text(scaling)
                .font(.system(size: 12))
                .foregroundStyle(theme.inkTertiary)
        }
    }

    @ViewBuilder
    private func actualView(_ row: Row) -> some View {
        switch row.actual {
        case .none:
            Text("—")
                .font(.system(size: 14))
                .foregroundStyle(theme.inkTertiary)

        case .done:
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(accent)

        case let .weight(value, rx):
            VStack(alignment: .trailing, spacing: 1) {
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(accent)
                if rx {
                    Text("RX")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(theme.inkTertiary)
                }
            }

        case let .partial(done, total):
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(done)")
                    .font(.system(size: 14, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(.orange)
                Text("/ \(total)")
                    .font(.system(size: 11))
                    .monospacedDigit()
                    .foregroundStyle(theme.inkTertiary)
            }
        }
    }

    // MARK: - Limit separator

    private func limitSeparator(_ text: String) -> some View {
        HStack(spacing: 8) {
            separatorLine
            Text(text)
                .font(.system(size: 10, weight: .heavy))
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(.orange)
            separatorLine
        }
        .padding(.vertical, 6)
    }

    private var separatorLine: some View {
        Rectangle()
            .fill(Color.orange.opacity(0.35))
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews

#Preview("ExerciseList — warianty wiersza + limit (galeria 7)") {
    VStack {
        ExerciseList(
            items: [
                .exercise(.init(repPrefix: "50×", name: "Double Unders", scaling: nil, actual: .none, isMuted: true)),
                .exercise(.init(repPrefix: "10×", name: "Thrusters", scaling: "40/30 kg", actual: .weight("40 kg", rx: true))),
                .exercise(.init(repPrefix: "15×", name: "Bar-Facing Burpees", scaling: nil, actual: .done)),
                .exercise(.init(repPrefix: "30×", name: "Thrusters", scaling: "40/30 kg", actual: .partial(done: 12, total: 30))),
                .limit(text: "limit 12:00"),
                .exercise(.init(repPrefix: "35×", name: "Bar-Facing Burpees", scaling: nil, actual: .none, isMuted: true)),
            ],
            accent: SummaryTheme.mint
        )
    }
    .summaryCard()
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SummaryTheme.background)
}
