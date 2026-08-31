//
//  SummaryTheme.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/07/2026.
//

import SwiftUI

/// Design tokens for the workout Summary screen, lifted 1:1 from the approved
/// mockup so every component previews against the exact target look.
///
/// The screen accent is deliberately NOT a token — it follows the dominant
/// HR zone of the whole workout and only falls back to `mint` when there is
/// no zone data (see `SummaryView.accent`).
enum SummaryTheme {

    // MARK: - Surfaces

    /// Screen background (#0A0F0C).
    static let background = Color(red: 10 / 255, green: 15 / 255, blue: 12 / 255)

    /// Card surface (#131A16).
    static let card = Color(red: 19 / 255, green: 26 / 255, blue: 22 / 255)

    /// Inner tile surface — fields and score lines nested inside a card (#1A231E).
    static let cardInner = Color(red: 26 / 255, green: 35 / 255, blue: 30 / 255)

    /// Hairline stroke around cards and inner tiles (white 7%).
    static let stroke = Color.white.opacity(0.07)

    // MARK: - Text

    /// Primary text (#F2F7F4).
    static let ink = Color(red: 242 / 255, green: 247 / 255, blue: 244 / 255)

    /// Secondary text — metadata, units, section subtitles (#9FB3A8).
    static let inkSecondary = Color(red: 159 / 255, green: 179 / 255, blue: 168 / 255)

    /// Tertiary text — hints, placeholders, axis labels (#5E7268).
    static let inkTertiary = Color(red: 94 / 255, green: 114 / 255, blue: 104 / 255)

    // MARK: - Brand & chips

    /// App identity mint (#34E39A). Two roles: accent FALLBACK when no HR-zone
    /// data exists, and fixed identity spots (Effort Points icon, PR chip)
    /// that never repaint with the zone.
    static let mint = Color(red: 52 / 255, green: 227 / 255, blue: 154 / 255)

    /// Mint at tile-tint strength.
    static let mintDim = mint.opacity(0.14)

    /// Strength / Olympic type chip (#FF9F0A).
    static let strengthChip = Color(red: 255 / 255, green: 159 / 255, blue: 10 / 255)

    /// WOD type chip (#4A9DFF).
    static let wodChip = Color(red: 74 / 255, green: 157 / 255, blue: 255 / 255)

    /// Text on accent-filled controls, e.g. the save CTA (#062416).
    /// Dark enough to stay readable on every zone color.
    static let onAccent = Color(red: 6 / 255, green: 36 / 255, blue: 22 / 255)

    // MARK: - Metrics

    /// Corner radius of top-level cards.
    static let cardRadius: CGFloat = 22

    /// Corner radius of inner tiles (score line, DNF fields, set table).
    static let innerRadius: CGFloat = 14

    /// Default inner padding of a card.
    static let cardPadding: CGFloat = 16
}

// MARK: - Palette (theme)

/// Surface + text colors resolved per host. The result section renders dark
/// (mockup skin) inside the Summary screen and native (adaptive, matching the
/// app's `styledGroupBox` cards) inside Activity Details. Brand colors (mint,
/// chips) are identical in both; only surfaces and text adapt.
struct SummaryPalette {

    let background: Color
    let card: Color
    let cardInner: Color
    let stroke: Color
    let strokeWidth: CGFloat
    let ink: Color
    let inkSecondary: Color
    let inkTertiary: Color
    let mint: Color
    let strengthChip: Color
    let wodChip: Color
    let onAccent: Color

    var mintDim: Color { mint.opacity(0.14) }

    /// Dark mockup skin — the Summary screen.
    static let dark = SummaryPalette(
        background: SummaryTheme.background,
        card: SummaryTheme.card,
        cardInner: SummaryTheme.cardInner,
        stroke: SummaryTheme.stroke,
        strokeWidth: 1,
        ink: SummaryTheme.ink,
        inkSecondary: SummaryTheme.inkSecondary,
        inkTertiary: SummaryTheme.inkTertiary,
        mint: SummaryTheme.mint,
        strengthChip: SummaryTheme.strengthChip,
        wodChip: SummaryTheme.wodChip,
        onAccent: SummaryTheme.onAccent
    )

    /// Native adaptive skin — matches the app's `styledGroupBox` cards on the
    /// Activity Details screen (light/dark aware, system surfaces).
    static let native = SummaryPalette(
        background: .clear,
        card: Color(.secondarySystemBackground),
        cardInner: Color(.tertiarySystemBackground),
        stroke: .gray.opacity(0.5),
        strokeWidth: 0.5,
        ink: .primary,
        inkSecondary: .secondary,
        inkTertiary: Color(.tertiaryLabel),
        mint: SummaryTheme.mint,
        strengthChip: SummaryTheme.strengthChip,
        wodChip: SummaryTheme.wodChip,
        onAccent: .white
    )
}

private struct SummaryPaletteKey: EnvironmentKey {
    static let defaultValue = SummaryPalette.dark
}

extension EnvironmentValues {
    var summaryPalette: SummaryPalette {
        get { self[SummaryPaletteKey.self] }
        set { self[SummaryPaletteKey.self] = newValue }
    }
}

// MARK: - Card chrome

private struct SummaryCardModifier: ViewModifier {

    @Environment(\.summaryPalette) private var theme

    func body(content: Content) -> some View {
        content
            .padding(SummaryTheme.cardPadding)
            .background(theme.card, in: .rect(cornerRadius: SummaryTheme.cardRadius))
            .overlay(cardStroke)
    }

    private var cardStroke: some View {
        RoundedRectangle(cornerRadius: SummaryTheme.cardRadius)
            .stroke(theme.stroke, lineWidth: theme.strokeWidth)
    }
}

extension View {

    /// Card chrome — resolves dark (Summary) or native (Activity Details) from
    /// the `summaryPalette` environment.
    func summaryCard() -> some View {
        modifier(SummaryCardModifier())
    }
}

// MARK: - Preview

#Preview("SummaryTheme — card chrome") {
    ScrollView {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Primary ink")
                    .font(.headline)
                    .foregroundStyle(SummaryTheme.ink)
                Text("Secondary — metadata, units")
                    .font(.subheadline)
                    .foregroundStyle(SummaryTheme.inkSecondary)
                Text("Tertiary — hints, placeholders")
                    .font(.footnote)
                    .foregroundStyle(SummaryTheme.inkTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .summaryCard()

            VStack(alignment: .leading, spacing: 10) {
                Text("Inner tile")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SummaryTheme.ink)
                Text("cardInner + innerRadius")
                    .font(.footnote)
                    .foregroundStyle(SummaryTheme.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(
                        SummaryTheme.cardInner,
                        in: .rect(cornerRadius: SummaryTheme.innerRadius)
                    )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .summaryCard()

            HStack(spacing: 8) {
                Text("mint")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SummaryTheme.mint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(SummaryTheme.mintDim, in: .capsule)
                Text("strength")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SummaryTheme.strengthChip)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(SummaryTheme.strengthChip.opacity(0.13), in: .capsule)
                Text("wod")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SummaryTheme.wodChip)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(SummaryTheme.wodChip.opacity(0.13), in: .capsule)
                Spacer()
            }
            .summaryCard()
        }
        .padding(16)
    }
    .background(SummaryTheme.background)
}
