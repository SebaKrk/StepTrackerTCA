//
//  MetricTile.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/07/2026.
//

import SwiftUI

/// Mockup R3 — one configurable metric tile: colored icon chip + uppercase
/// label on top, big value with a small unit below. Rendered in a 2×2 grid
/// on the Summary screen (Kcal / Effort Points / Avg HR / Max HR).
struct MetricTile: View {

    // MARK: - Properties

    let iconSystemName: String
    let iconColor: Color
    let title: String
    let value: String
    let unit: String

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            tileLabel
            tileValue
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .summaryCard()
    }

    // MARK: - Implementation

    private var tileLabel: some View {
        HStack(spacing: 7) {
            iconChip
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundStyle(SummaryTheme.inkSecondary)
                .lineLimit(2, reservesSpace: false)
        }
    }

    private var iconChip: some View {
        Image(systemName: iconSystemName)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(iconColor)
            .frame(width: 24, height: 24)
            .background(iconColor.opacity(0.15), in: .rect(cornerRadius: 8))
    }

    private var tileValue: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(value)
                .font(.system(size: 30, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(SummaryTheme.ink)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            if !unit.isEmpty {
                Text(unit)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SummaryTheme.inkSecondary)
            }
        }
    }
}

// MARK: - Previews

#Preview("MetricTile — siatka 2×2 (makieta)") {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        MetricTile(
            iconSystemName: "flame.fill",
            iconColor: .orange,
            title: "Kcal z aktywności",
            value: "503",
            unit: "kcal"
        )
        MetricTile(
            iconSystemName: "bolt.fill",
            iconColor: SummaryTheme.mint,
            title: "Effort Points",
            value: "159",
            unit: "pts"
        )
        MetricTile(
            iconSystemName: "heart.fill",
            iconColor: Color(red: 255 / 255, green: 100 / 255, blue: 130 / 255),
            title: "Śr. tętno",
            value: "119",
            unit: "bpm"
        )
        MetricTile(
            iconSystemName: "waveform.path.ecg",
            iconColor: .red,
            title: "Max heart rate",
            value: "171",
            unit: "bpm"
        )
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SummaryTheme.background)
}

#Preview("MetricTile — fallback Czas (manual entry)") {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        MetricTile(
            iconSystemName: "flame.fill",
            iconColor: .orange,
            title: "Kcal z aktywności",
            value: "380",
            unit: "kcal"
        )
        MetricTile(
            iconSystemName: "timer",
            iconColor: SummaryTheme.mint,
            title: "Czas",
            value: "45:32",
            unit: ""
        )
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SummaryTheme.background)
}
