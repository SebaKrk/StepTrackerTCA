//
//  PRMovement.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 31/08/2026.
//

import Foundation

/// Score kind of a PR Board movement — drives the input control and the
/// "better result" direction (time: lower wins; amrap: lexicographic).
public enum PRScoreType: String, Codable, Sendable {
    case weight
    case time
    case reps
    case amrap
}

/// Subgroup within a `PRCategory`, used to section movement lists.
public enum PRSubgroup: String, CaseIterable, Codable, Sendable {
    case snatchFamily
    case cleanFamily
    case squats
    case pulls
    case presses
    case barGymnastics
    case handstand
    case rowing
    case running
    case cycling
    case girls
    case heroes

    public var displayName: String {
        switch self {
        case .snatchFamily:  return String(localized: "Snatch", bundle: .module)
        case .cleanFamily:   return String(localized: "Clean & Jerk", bundle: .module)
        case .squats:        return String(localized: "Squats", bundle: .module)
        case .pulls:         return String(localized: "Deadlifts", bundle: .module)
        case .presses:       return String(localized: "Presses", bundle: .module)
        case .barGymnastics: return String(localized: "Bar & Rings", bundle: .module)
        case .handstand:     return String(localized: "Handstand", bundle: .module)
        case .rowing:        return String(localized: "Rowing", bundle: .module)
        case .running:       return String(localized: "Running", bundle: .module)
        case .cycling:       return String(localized: "Cycling", bundle: .module)
        case .girls:         return String(localized: "The Girls", bundle: .module)
        case .heroes:        return String(localized: "Hero WODs", bundle: .module)
        }
    }
}

/// A single entry of the static PR Board catalog.
/// Movement names stay in English by convention (gym jargon, matches `ExerciseType.displayName`).
public struct PRMovement: Identifiable, Codable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let category: PRCategory
    public let subgroup: PRSubgroup
    public let scoreType: PRScoreType
    public let supportsRxScaled: Bool
    /// Rx standard note shown on benchmark detail (nil outside Benchmarks).
    public let rxStandard: String?
    /// Dormant bridge to the exercise catalog — not consumed by any mechanism in MVP.
    public let exerciseType: ExerciseType?
    /// Dormant bridge for future WOD-name auto-detection — not consumed in MVP.
    public let wodAliases: [String]

    public init(
        id: String,
        name: String,
        category: PRCategory,
        subgroup: PRSubgroup,
        scoreType: PRScoreType,
        supportsRxScaled: Bool = false,
        rxStandard: String? = nil,
        exerciseType: ExerciseType? = nil,
        wodAliases: [String] = []
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.subgroup = subgroup
        self.scoreType = scoreType
        self.supportsRxScaled = supportsRxScaled
        self.rxStandard = rxStandard
        self.exerciseType = exerciseType
        self.wodAliases = wodAliases
    }
}
