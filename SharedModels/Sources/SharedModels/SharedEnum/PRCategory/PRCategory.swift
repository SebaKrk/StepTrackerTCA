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
        case .strength:     return String(localized: "Strength", bundle: .module)
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
}
