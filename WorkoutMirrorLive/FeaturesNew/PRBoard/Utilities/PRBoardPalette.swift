//
//  PRBoardPalette.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 04/09/2026.
//

import SwiftUI

/// Dark visual identity of the PR Board screens (mockup "Tablica PR — redesign").
/// Shared by the hub, the movement list, and the movement detail.
enum PRBoardPalette {

    // MARK: - Surfaces

    static let base = Color(red: 0.039, green: 0.059, blue: 0.047)
    static let card = Color(red: 0.075, green: 0.102, blue: 0.086)
    static let cardElevated = Color(red: 0.102, green: 0.137, blue: 0.118)
    static let stroke = Color.white.opacity(0.07)
    static let trackFill = Color.white.opacity(0.07)
    static let hairline = Color.white.opacity(0.05)

    // MARK: - Ink

    static let ink = Color(red: 0.949, green: 0.969, blue: 0.957)
    static let inkSecondary = Color(red: 0.624, green: 0.702, blue: 0.659)
    static let inkTertiary = Color(red: 0.369, green: 0.447, blue: 0.408)

    // MARK: - Accents

    static let mint = Color(red: 0.204, green: 0.890, blue: 0.604)
    static let mintInk = Color(red: 0.039, green: 0.165, blue: 0.106)
    static let gold = Color(red: 1.0, green: 0.839, blue: 0.039)
    static let goldInk = Color(red: 0.165, green: 0.102, blue: 0.0)

    // MARK: - Screen chrome

    /// Full-screen background: dark base with a radial glow in the screen accent.
    static func screenBackground(glow: Color) -> some View {
        base
            .overlay(alignment: .top) {
                RadialGradient(
                    colors: [glow.opacity(0.14), .clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: 420
                )
            }
            .ignoresSafeArea()
    }
}

extension View {

    /// Dark PR Board card: fill, 22pt corners, hairline stroke.
    func prCard() -> some View {
        background(
            RoundedRectangle(cornerRadius: 22)
                .fill(PRBoardPalette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(PRBoardPalette.stroke, lineWidth: 1)
                )
        )
    }
}
