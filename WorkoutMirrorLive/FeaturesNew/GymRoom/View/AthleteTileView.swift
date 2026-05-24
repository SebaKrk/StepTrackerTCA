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
/// Layout 1:1 z `landscapeMetricsCard` z `LiveSessionView` (iPhone landscape):
/// - Lewy górny: avatar `[X]` + heart icon + BPM
/// - Prawy górny: zone title
/// - Środek: BIG %HR + 🔥 kcal Active Energy
/// - Lewy dolny: pełna nazwa atlety
///
/// Tło: gradient HR zone color + Liquid Glass effect (iOS 26).
struct AthleteTileView: View {

    let athlete: GymRoomFeature.AthleteTile

    var body: some View {
        VStack(spacing: 0) {
            header
            Spacer()
            VStack(spacing: 12) {
                percentageView
                activeEnergyView
            }
            Spacer()
            footer
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(zoneGradient, in: tileShape)
        .glassEffect(in: tileShape)
        .animation(.easeInOut(duration: 0.4), value: athlete.zone)
    }

    private var tileShape: some Shape {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
    }

    // MARK: - Private views (struktura)

    private var header: some View {
        HStack(alignment: .center) {
            HStack(spacing: 10) {
                avatarBadge
                heartRateRow
            }
            Spacer()
            zoneTitleLabel
        }
    }

    private var footer: some View {
        HStack {
            Text(athlete.id)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
            Spacer()
        }
    }

    private var activeEnergyView: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .foregroundStyle(.pink)
                .font(.system(.body, design: .rounded))
            Text("\(Int(athlete.activeEnergy)) kcal")
                .font(.system(.title3, design: .rounded, weight: .semibold).monospacedDigit())
                .foregroundStyle(.white)
                .contentTransition(.numericText(value: athlete.activeEnergy))
                .animation(.snappy(duration: 0.3), value: athlete.activeEnergy)
            VStack(alignment: .leading, spacing: 0) {
                Text("Active")
                Text("Energy")
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.75))
        }
    }

    private var avatarBadge: some View {
        Text(initialLetter)
            .font(.title3.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(.regularMaterial, in: .circle)
            .overlay(Circle().stroke(athlete.zone.color.opacity(0.5), lineWidth: 1.5))
    }

    private var heartRateRow: some View {
        HStack(spacing: 4) {
            Image(systemName: "heart.fill")
                .foregroundStyle(.red)
                .font(.system(.callout, design: .rounded))
                .symbolEffect(.pulse, options: .repeating, value: athlete.bpm)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(athlete.bpm.formatted(.number))
                    .font(.system(.callout, design: .rounded, weight: .semibold).monospacedDigit())
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(value: Double(athlete.bpm)))
                    .animation(.snappy(duration: 0.3), value: athlete.bpm)
                Text("BPM")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    private var zoneTitleLabel: some View {
        // Spójność z iPhone landscape: kolorowy tekst (bez pilla), foreground = zone color.
        Text(athlete.zone.title)
            .font(.title3.weight(.semibold))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
    }

    private var percentageView: some View {
        Text(percentText)
            .font(.system(size: 140, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white)
            .contentTransition(.numericText(value: Double(athlete.percentHR)))
            .animation(.snappy(duration: 0.3), value: athlete.percentHR)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
    }

    // MARK: - Private content (implementacja)

    private var percentText: String {
        "\(athlete.percentHR)%"
    }

    private var initialLetter: String {
        String(athlete.id.first ?? "?").uppercased()
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
}

// MARK: - Previews

/// Wszystkie 6 stref HR naraz — bpm dobrane tak żeby każdy tile miał inną strefę.
private let allZonesPreviewAthletes: [GymRoomFeature.AthleteTile] = [
    .init(id: "Sebastian", bpm: 60,  maxHR: 190, activeEnergy: 0),     // resting     (~31%)
    .init(id: "Anna",      bpm: 102, maxHR: 190, activeEnergy: 45),    // recovery    (~53%)
    .init(id: "Janek",     bpm: 124, maxHR: 190, activeEnergy: 120),   // fatBurning  (~65%)
    .init(id: "Maria",     bpm: 142, maxHR: 190, activeEnergy: 210),   // aerobic     (~74%)
    .init(id: "Tomek",     bpm: 162, maxHR: 190, activeEnergy: 340),   // threshold   (~85%)
    .init(id: "Kasia",     bpm: 180, maxHR: 190, activeEnergy: 480),   // anaerobic   (~94%)
]

#Preview("All Zones — Grid") {
    ScrollView {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 360), spacing: 20)],
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
        athlete: GymRoomFeature.AthleteTile(id: "Anna", bpm: 162, maxHR: 185)
    )
    .padding(20)
    .frame(width: 420, height: 360)
    .background(.black)
    .preferredColorScheme(.dark)
}

/// Test layoutu dla różnych długości "X kcal" — od 0 do 4-cyfrowych wartości.
/// Wszyscy w tej samej strefie (Threshold) żeby widać było tylko różnice w energy display.
private let differentCaloriesPreviewAthletes: [GymRoomFeature.AthleteTile] = [
    .init(id: "Start",       bpm: 160, maxHR: 190, activeEnergy: 0),      // "0 kcal" — początek treningu
    .init(id: "Warm-up",     bpm: 160, maxHR: 190, activeEnergy: 85),     // "85 kcal" — 2-cyfra
    .init(id: "Mid-session", bpm: 160, maxHR: 190, activeEnergy: 420),    // "420 kcal" — 3-cyfra
    .init(id: "Endurance",   bpm: 160, maxHR: 190, activeEnergy: 1250),   // "1250 kcal" — 4-cyfra
    .init(id: "Marathon",    bpm: 160, maxHR: 190, activeEnergy: 2800),   // "2800 kcal" — long workout
    .init(id: "Ultra",       bpm: 160, maxHR: 190, activeEnergy: 4500),   // "4500 kcal" — extreme
]

#Preview("Different Calories") {
    ScrollView {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 360), spacing: 20)],
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
