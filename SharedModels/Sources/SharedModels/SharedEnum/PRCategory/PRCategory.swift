//
//  PRCategory.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 31/08/2026.
//

import Foundation
import SwiftUI

/// Fixed top-level categories of the PR Board catalog.
/// Intentionally separate from `MovementCategory` — the PR Board needs
/// Benchmarks as a first-class category and none of mobility/mixed.
public enum PRCategory: String, CaseIterable, Codable, Sendable, Identifiable {
    case olympic
    case strength
    case gymnastics
    case conditioning
    case benchmarks

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .olympic:      return String(localized: "Olympic Lifts", bundle: .module)
        // Dedicated key — plain "Strength" is the workout-type label ("Trening siłowy").
        case .strength:     return String(localized: "Strength category", bundle: .module)
        case .gymnastics:   return String(localized: "Gymnastics", bundle: .module)
        case .conditioning: return String(localized: "Conditioning", bundle: .module)
        case .benchmarks:   return String(localized: "Benchmarks", bundle: .module)
        }
    }

    public var color: Color {
        switch self {
        case .olympic:      return .purple
        case .strength:     return .orange
        case .gymnastics:   return .blue
        case .conditioning: return .green
        case .benchmarks:   return .red
        }
    }

    /// Icon shown on the category tile of the PR Board hub.
    public var sfSymbolName: String {
        switch self {
        case .olympic:      return "figure.strengthtraining.traditional"
        case .strength:     return "dumbbell.fill"
        case .gymnastics:   return "figure.gymnastics"
        case .conditioning: return "waveform.path.ecg"
        case .benchmarks:   return "star.fill"
        }
    }
}
