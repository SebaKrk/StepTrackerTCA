//
//  Equipment.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 19/09/2026.
//

import Foundation

/// Training implement an exercise is performed with, independent of the movement.
///
/// Kept separate from `ExerciseType` so the catalog does not have to enumerate every
/// implement × movement combination: `goblet squat` is one entry, the implement rides
/// alongside it.
public enum Equipment: String, CaseIterable, Codable, Sendable {

    /// Olympic barbell.
    case barbell

    /// One or two dumbbells.
    case dumbbell

    /// One or two kettlebells.
    case kettlebell

    /// Medicine ball or wall ball.
    case medicineBall

    /// Full name for detail screens.
    public var displayName: String {
        switch self {
        case .barbell:      return String(localized: "Barbell", bundle: .module)
        case .dumbbell:     return String(localized: "Dumbbell", bundle: .module)
        case .kettlebell:   return String(localized: "Kettlebell", bundle: .module)
        case .medicineBall: return String(localized: "Medicine ball", bundle: .module)
        }
    }

    /// Prefix used when composing an exercise name ("Dumbbell Shoulder Press").
    ///
    /// Deliberately NOT localized, unlike `displayName`: movement names in the catalog
    /// are English by convention, so a translated prefix would read half in one
    /// language and half in the other ("Hantel Goblet Squat").
    public var namePrefix: String {
        switch self {
        case .barbell:      return "Barbell"
        case .dumbbell:     return "Dumbbell"
        case .kettlebell:   return "Kettlebell"
        case .medicineBall: return "Medicine Ball"
        }
    }

    /// Whether the implement always carries load, so a weight field must be offered.
    ///
    /// Spelled out per case rather than returning `true`: adding an unloaded implement
    /// must break the build here instead of silently claiming a weight field.
    public var impliesLoad: Bool {
        switch self {
        case .barbell, .dumbbell, .kettlebell, .medicineBall:
            return true
        }
    }
}

/// User decision for the equipment used by a planned exercise.
/// `automatic` keeps the scanned value when present, then falls back to the
/// movement's catalog default. `none` is an explicit bodyweight/no-implement choice.
public enum ExerciseEquipmentSelection: Equatable, Hashable, Codable, Sendable {
    case automatic
    case none
    case equipment(Equipment)

    public var storageValue: String {
        switch self {
        case .automatic: "automatic"
        case .none: "none"
        case let .equipment(equipment): "equipment:\(equipment.rawValue)"
        }
    }

    public init?(storageValue: String) {
        switch storageValue {
        case "automatic": self = .automatic
        case "none": self = .none
        default:
            guard storageValue.hasPrefix("equipment:"),
                  let equipment = Equipment(rawValue: String(storageValue.dropFirst("equipment:".count)))
            else { return nil }
            self = .equipment(equipment)
        }
    }
}
