//
//  HRBeltIcon.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 18/07/2026.
//

import SwiftUI

/// Chest-strap glyph for the device picker — no SF Symbol exists for an
/// HR belt, so it is drawn to match the SF style: a thin outlined band
/// filled with the tint at low opacity, a filled square sensor pod in the
/// middle and a white heart on the pod.
///
/// Inherits the surrounding `foregroundStyle` like a system symbol, so the
/// picker's selected/unselected tinting works unchanged.
struct HRBeltIcon: View {

    /// Glyph width in points — every metric scales from the 92×38 design grid.
    var width: CGFloat = 34

    var body: some View {
        ZStack {
            band
            sensor
            heart
        }
        .frame(width: width, height: 38 * unit)
    }

    // MARK: - Implementation

    private var unit: CGFloat { width / 92 }

    private var band: some View {
        Capsule()
            .opacity(bandFillOpacity)
            .overlay(Capsule().stroke(lineWidth: 1.5 * unit).opacity(bandStrokeOpacity))
            .frame(width: 90 * unit, height: 15 * unit)
    }

    private var sensor: some View {
        RoundedRectangle(cornerRadius: 10 * unit)
            .frame(width: 38 * unit, height: 38 * unit)
    }

    private var heart: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 17 * unit))
            .foregroundStyle(.white)
    }

    private var bandFillOpacity: Double { 0.15 }
    private var bandStrokeOpacity: Double { 0.5 }
}

#Preview("HR belt icon", traits: .sizeThatFitsLayout) {
    HStack(spacing: 24) {
        HRBeltIcon(width: 68)
            .foregroundStyle(.secondary)
        HRBeltIcon()
            .foregroundStyle(.secondary)
        HRBeltIcon()
            .foregroundStyle(.pink)
    }
    .padding()
}
