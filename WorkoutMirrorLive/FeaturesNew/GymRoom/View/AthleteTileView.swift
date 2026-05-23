//
//  AthleteTileView.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 23/05/2026.
//

import SwiftUI

/// Pojedynczy kafelek athlety w `GymRoomView` grid.
///
/// Layout: nick (góra) → BIG %HR (środek) → bpm (dół).
/// Tło: deterministyczny kolor z hash'a nicka.
struct AthleteTileView: View {

    let athlete: GymRoomFeature.AthleteTile

    var body: some View {
        VStack(spacing: 16) {
            nickLabel
            percentHRLabel
            bpmLabel
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(tileBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    // MARK: - Private views

    private var nickLabel: some View {
        Text(athlete.id)
            .font(nickFont)
            .foregroundStyle(.white)
    }

    private var percentHRLabel: some View {
        Text(percentHRText)
            .font(percentFont)
            .foregroundStyle(.white)
    }

    private var bpmLabel: some View {
        Text(bpmText)
            .font(.caption)
            .foregroundStyle(.white.opacity(0.7))
    }

    // MARK: - Private content

    private var percentHRText: String {
        "\(athlete.percentHR)%"
    }

    private var bpmText: String {
        String(localized: "\(athlete.bpm) bpm", bundle: .main)
    }

    private var nickFont: Font {
        .title2.weight(.semibold)
    }

    private var percentFont: Font {
        .system(size: 100, weight: .bold, design: .rounded)
    }

    private var tileBackground: Color {
        let hue = Double(abs(athlete.id.hashValue) % 360) / 360
        return Color(hue: hue, saturation: 0.6, brightness: 0.7)
    }
}

#Preview {
    AthleteTileView(
        athlete: GymRoomFeature.AthleteTile(id: "Sebastian", bpm: 152, maxHR: 190)
    )
    .padding(40)
    .background(.black)
}
