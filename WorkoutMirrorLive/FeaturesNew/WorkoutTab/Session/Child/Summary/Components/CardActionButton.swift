//
//  CardActionButton.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/07/2026.
//

import SwiftUI

/// Full-width action button of a result card ("Wpisz wyniki ›" / "Gotowe ›").
/// Liquid Glass, untinted — the only tinted control on screen is the save button.
struct CardActionButton: View {

    // MARK: - Properties

    let title: String
    let action: () -> Void
    @Environment(\.summaryPalette) private var theme
    // MARK: - Body

    var body: some View {
        Button {
            action()
        } label: {
            buttonLabel
        }
        .buttonStyle(.glass)
    }

    // MARK: - Implementation

    private var buttonLabel: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(theme.inkSecondary)
        }
        .foregroundStyle(theme.ink)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}

// MARK: - Previews

#Preview("CardActionButton — 3 etykiety") {
    VStack(spacing: 12) {
        VStack(spacing: 10) {
            Text("Karta WOD")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SummaryTheme.inkSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            CardActionButton(title: "Wpisz wyniki", action: {})
        }
        .summaryCard()

        VStack(spacing: 10) {
            Text("Karta Strength")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SummaryTheme.inkSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            CardActionButton(title: "Wpisz serie", action: {})
        }
        .summaryCard()

        VStack(spacing: 10) {
            Text("Karta w edycji")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SummaryTheme.inkSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            CardActionButton(title: "Gotowe", action: {})
        }
        .summaryCard()
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SummaryTheme.background)
}
