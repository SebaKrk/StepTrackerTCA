//
//  AthleteTileView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 23/05/2026.
//

import SharedModels
import SwiftUI

/// Pojedynczy kafelek athlety w `GymRoomView` grid.
///
/// Layout:
/// - Lewy górny: avatar `[X]`
/// - Prawy górny: heart icon + BPM
/// - Środek: BIG %HR + 🔥 kcal Active Energy
/// - Lewy dolny: pełna nazwa atlety
/// - Prawy dolny: zone title (secondary opacity)
///
/// Tło: gradient HR zone color + Liquid Glass effect (iOS 26).
struct AthleteTileView: View {

    let athlete: GymRoomFeature.AthleteTile

    /// Wysokość kafelka — używana do proporcjonalnego skalowania fontów i paddingu.
    /// Default 213pt (= 320/1.5 dla 3:2 aspect). Mniejszy tile → wszystko proporcjonalnie mniejsze.
    var tileHeight: CGFloat = 213

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header
            Spacer(minLength: 0)
            middleSection
            Spacer(minLength: bottomSpacerMinLength)
            footer
        }
        .padding(tilePadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(zoneGradient, in: tileShape)
        .glassEffect(in: tileShape)
        .clipShape(tileShape)
        .animation(.easeInOut(duration: 0.4), value: athlete.zone)
    }

    // MARK: - Private views (struktura)

    /// Wiersz górny: avatar po lewej, serce + BPM po prawej.
    private var header: some View {
        HStack(alignment: .center) {
            avatarBadge
            Spacer()
            heartRateRow
        }
    }

    /// Środkowa sekcja: duży %HR + active energy pod nim.
    private var middleSection: some View {
        VStack(spacing: middleVStackSpacing) {
            percentageView
            activeEnergyView
        }
    }

    /// Wiersz dolny: pełne imię po lewej, zone title (secondary) po prawej.
    private var footer: some View {
        HStack(alignment: .firstTextBaseline) {
            nameLabel
            Spacer()
            zoneLabel
        }
    }

    /// Avatar z pierwszą literą nicka + Liquid Glass background + zone color border.
    private var avatarBadge: some View {
        Text(initialLetter)
            .font(avatarFont)
            .foregroundStyle(.white)
            .frame(width: avatarSize, height: avatarSize)
            .background(.regularMaterial, in: .circle)
            .overlay(Circle().stroke(avatarBorderColor, lineWidth: avatarBorderWidth))
    }

    /// `❤️ 152 BPM` w jednym wierszu — heart icon (pulse animation) + liczba + caption.
    private var heartRateRow: some View {
        HStack(spacing: heartRateInnerSpacing) {
            heartIcon
            HStack(alignment: .firstTextBaseline, spacing: heartRateInnerSpacing) {
                bpmValue
                bpmCaption
            }
        }
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
    }

    /// Duży procent HR — central focal point kafelka.
    private var percentageView: some View {
        Text(percentText)
            .font(bigPercentFont)
            .monospacedDigit()
            .foregroundStyle(.white)
            .contentTransition(.numericText(value: Double(athlete.percentHR)))
            .animation(.snappy(duration: 0.3), value: athlete.percentHR)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .waitingPulse(isActive: athlete.bpm == 0)
    }

    /// `🔥 45 kcal Active Energy` — flame + liczba + caption w jednym wierszu.
    private var activeEnergyView: some View {
        HStack(spacing: kcalInnerSpacing) {
            kcalIcon
            kcalValue
            kcalCaption
        }
        .lineLimit(1)
    }

    /// Imię atlety w lewym dolnym rogu.
    private var nameLabel: some View {
        Text(athlete.nick)
            .font(nameFont)
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }

    /// Zone title (secondary opacity) w prawym dolnym rogu.
    private var zoneLabel: some View {
        Text(athlete.zone.title)
            .font(zoneFont)
            .foregroundStyle(.white.opacity(zoneSecondaryOpacity))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }

    /// Sub-elementy `heartRateRow` — wyciągnięte dla View Facade clarity.
    private var heartIcon: some View {
        Image(systemName: heartSymbol)
            .foregroundStyle(.red)
            .font(heartIconFont)
            .symbolEffect(.pulse, options: .repeating, value: athlete.bpm)
    }

    private var bpmValue: some View {
        Text(bpmValueText)
            .font(bpmValueFont)
            .foregroundStyle(.white)
            .contentTransition(.numericText(value: Double(athlete.bpm)))
            .animation(.snappy(duration: 0.3), value: athlete.bpm)
            .waitingPulse(isActive: athlete.bpm == 0)
    }

    private var bpmCaption: some View {
        Text(bpmCaptionText)
            .font(bpmCaptionFont)
            .foregroundStyle(.white.opacity(captionOpacity))
    }

    /// Sub-elementy `activeEnergyView`.
    private var kcalIcon: some View {
        Image(systemName: flameSymbol)
            .foregroundStyle(.pink)
            .font(kcalIconFont)
    }

    private var kcalValue: some View {
        Text(kcalValueText)
            .font(kcalValueFont)
            .foregroundStyle(.white)
            .contentTransition(.numericText(value: athlete.activeEnergy))
            .animation(.snappy(duration: 0.3), value: athlete.activeEnergy)
    }

    private var kcalCaption: some View {
        Text(kcalCaptionText)
            .font(kcalCaptionFont)
            .foregroundStyle(.white.opacity(captionOpacity))
    }

    // MARK: - Private content (implementacja)

    /// Skala względem default — proporcjonalnie zmniejsza fonty i spacing przy małych tile.
    /// Clamp 0.5...1.0 — content nigdy mniej niż 50% defaultu (czytelność floor).
    private var scale: CGFloat {
        max(0.5, min(1.0, tileHeight / referenceTileHeight))
    }

    /// Reference height dla scale = 1.0 (default tile 320×213, aspect 3:2).
    private var referenceTileHeight: CGFloat { 213 }

    // MARK: - Spacing / Sizing

    private var tilePadding: CGFloat { 16 * scale }
    private var middleVStackSpacing: CGFloat { 4 * scale }
    private var bottomSpacerMinLength: CGFloat { 16 * scale }
    private var heartRateInnerSpacing: CGFloat { 4 * scale }
    private var kcalInnerSpacing: CGFloat { 5 * scale }
    private var avatarSize: CGFloat { 36 * scale }
    private var avatarBorderWidth: CGFloat { 1.5 }

    // MARK: - Fonts

    private var avatarFont: Font {
        .system(size: 18 * scale, weight: .bold)
    }

    private var bigPercentFont: Font {
        .system(size: 80 * scale, weight: .semibold, design: .rounded)
    }

    private var heartIconFont: Font {
        .system(size: 14 * scale, design: .rounded)
    }

    private var bpmValueFont: Font {
        .system(size: 15 * scale, weight: .semibold, design: .rounded).monospacedDigit()
    }

    private var bpmCaptionFont: Font {
        .system(size: 10 * scale)
    }

    private var kcalIconFont: Font {
        .system(size: 13 * scale, design: .rounded)
    }

    private var kcalValueFont: Font {
        .system(size: 15 * scale, weight: .semibold, design: .rounded).monospacedDigit()
    }

    private var kcalCaptionFont: Font {
        .system(size: 10 * scale)
    }

    private var nameFont: Font {
        .system(size: 17 * scale, weight: .semibold)
    }

    private var zoneFont: Font {
        .system(size: 13 * scale, weight: .medium)
    }

    // MARK: - Colors / Opacity

    private var avatarBorderColor: Color { athlete.zone.color.opacity(0.5) }
    private var captionOpacity: Double { 0.7 }
    private var zoneSecondaryOpacity: Double { 0.7 }

    // MARK: - Shapes / Gradients

    private var tileShape: some Shape {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
    }

    private var zoneGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: athlete.zone.color.opacity(0.85), location: 0),
                .init(color: athlete.zone.color.opacity(0.55), location: 0.4),
                .init(color: .black.opacity(0.4), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Symbol Names

    private var heartSymbol: String { "heart.fill" }
    private var flameSymbol: String { "flame.fill" }

    // MARK: - Texts

    /// "—" placeholder gdy bpm == 0 (athlete connected przez BLE ale brak HR sensor).
    /// Bez tego user widziałby "0 uderzeń/min" — sugerujące zatrzymane serce zamiast
    /// "czekamy na HR sensor".
    private var bpmValueText: String {
        athlete.bpm > 0 ? athlete.bpm.formatted(.number) : "—"
    }

    /// "—%" placeholder gdy bpm == 0 (percentHR też 0 w tym przypadku).
    /// Wizualnie spójne z `bpmValueText` — oba pokazują "—" dla "no HR yet" state.
    private var percentText: String {
        athlete.bpm > 0 ? "\(athlete.percentHR)%" : "—%"
    }

    private var kcalValueText: String {
        "\(Int(athlete.activeEnergy)) kcal"
    }

    private var kcalCaptionText: String {
        String(localized: "Active Energy", bundle: .main)
    }

    private var bpmCaptionText: String {
        String(localized: "BPM", bundle: .main)
    }

    private var initialLetter: String {
        String(athlete.nick.first ?? "?").uppercased()
    }
}

// MARK: - Previews

/// Wszystkie 6 stref HR naraz — bpm dobrane tak żeby każdy tile miał inną strefę.
private let allZonesPreviewAthletes: [GymRoomFeature.AthleteTile] = [
    .init(id: UUID(), nick: "Sebastian", bpm: 60,  maxHR: 190, activeEnergy: 0),
    .init(id: UUID(), nick: "Anna",      bpm: 102, maxHR: 190, activeEnergy: 45),
    .init(id: UUID(), nick: "Janek",     bpm: 124, maxHR: 190, activeEnergy: 120),
    .init(id: UUID(), nick: "Maria",     bpm: 142, maxHR: 190, activeEnergy: 210),
    .init(id: UUID(), nick: "Tomek",     bpm: 162, maxHR: 190, activeEnergy: 340),
    .init(id: UUID(), nick: "Kasia",     bpm: 180, maxHR: 190, activeEnergy: 480),
]

#Preview("All Zones — Grid") {
    ScrollView {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 320), spacing: 20)],
            spacing: 20
        ) {
            ForEach(allZonesPreviewAthletes) { athlete in
                AthleteTileView(athlete: athlete)
            }
        }
        .padding(20)
    }
    .background(.black)
    .preferredColorScheme(.dark)
}

#Preview("Single — Threshold") {
    AthleteTileView(
        athlete: GymRoomFeature.AthleteTile(id: UUID(), nick: "Anna", bpm: 162, maxHR: 185)
    )
    .padding(20)
    .frame(width: 420, height: 280)
    .background(.black)
    .preferredColorScheme(.dark)
}

/// Test layoutu dla różnych długości "X kcal" — od 0 do 4-cyfrowych wartości.
private let differentCaloriesPreviewAthletes: [GymRoomFeature.AthleteTile] = [
    .init(id: UUID(), nick: "Start",       bpm: 160, maxHR: 190, activeEnergy: 0),
    .init(id: UUID(), nick: "Warm-up",     bpm: 160, maxHR: 190, activeEnergy: 85),
    .init(id: UUID(), nick: "Mid-session", bpm: 160, maxHR: 190, activeEnergy: 420),
    .init(id: UUID(), nick: "Endurance",   bpm: 160, maxHR: 190, activeEnergy: 1250),
    .init(id: UUID(), nick: "Marathon",    bpm: 160, maxHR: 190, activeEnergy: 2800),
    .init(id: UUID(), nick: "Ultra",       bpm: 160, maxHR: 190, activeEnergy: 4500),
]

#Preview("Different Calories") {
    ScrollView {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 320), spacing: 20)],
            spacing: 20
        ) {
            ForEach(differentCaloriesPreviewAthletes) { athlete in
                AthleteTileView(athlete: athlete)
            }
        }
        .padding(20)
    }
    .background(.black)
    .preferredColorScheme(.dark)
}

// MARK: - Waiting Pulse Modifier

/// Subtelny pulse opacity (1.0 ↔ 0.4) dla placeholder'ów gdy czekamy na dane.
///
/// Używany w `AthleteTileView` na `bpmValue` i `percentageView` gdy `athlete.bpm == 0`
/// — komunikuje "aktywnie czekam na HR" zamiast "no data forever". Cykl 1.6s
/// (~37 bpm tempo) jest świadomie wolniejszy niż prawdziwe HR (60-180 bpm),
/// żeby user nie pomylił z aktywnym pulsem.
fileprivate extension View {
    @ViewBuilder
    func waitingPulse(isActive: Bool) -> some View {
        if isActive {
            self.phaseAnimator([1.0, 0.4]) { content, opacity in
                content.opacity(opacity)
            } animation: { _ in .easeInOut(duration: 0.8) }
        } else {
            self
        }
    }
}
