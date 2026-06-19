//
//  AthleteColor.swift
//  GymRoom
//
//  Created by Sebastian Ściuba on 18/06/2026.
//

import Foundation
import SwiftUI

/// Deterministyczny color picker dla athletes w History detail charts. Mapping
/// `deviceID` → kolor z palety — ten sam athlete dostaje ten sam kolor we wszystkich
/// chart'ach (combined line, per-athlete card, calories bar, future widgets).
///
/// **Algorytm**: stabilny hash z UUID bytes → modulo palety (12 colors). Apple HIG
/// recommended kolory dla data viz — wysoka kontrasrowość + accessibility-safe.
enum AthleteColor {

    private static let palette: [Color] = [
        .red, .blue, .green, .orange, .purple, .pink,
        .yellow, .mint, .indigo, .brown, .teal, .cyan
    ]

    /// Returns deterministic kolor dla peer'a. Stabilny przez restart app i pomiędzy
    /// sesjami — ten sam `deviceID` zawsze ten sam kolor.
    static func color(for deviceID: UUID) -> Color {
        let bytes = withUnsafeBytes(of: deviceID.uuid) { Array($0) }
        let hash = bytes.reduce(0) { ($0 &+ Int($1)) &* 31 }
        let index = abs(hash) % palette.count
        return palette[index]
    }
}
