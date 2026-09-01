//
//  PREntry.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 01/09/2026.
//

import Foundation

/// Score payload of a PR Board entry — one case per `PRScoreType`.
public enum PRScoreValue: Codable, Sendable, Equatable {
    case weight(kilograms: Double)
    case time(seconds: Int)
    case reps(count: Int)
    case amrap(rounds: Int, extraReps: Int)

    public var scoreType: PRScoreType {
        switch self {
        case .weight: return .weight
        case .time:   return .time
        case .reps:   return .reps
        case .amrap:  return .amrap
        }
    }
}

/// Equipment used for an entry (multi-select; drives the icon on the detail screen).
public enum PREquipment: String, CaseIterable, Codable, Sendable {
    case belt
    case kneeSleeves
    case wristWraps
    case straps
    case weightVest
    case chalk

    public var displayName: String {
        switch self {
        case .belt:        return String(localized: "Belt", bundle: .module)
        case .kneeSleeves: return String(localized: "Knee sleeves", bundle: .module)
        case .wristWraps:  return String(localized: "Wrist wraps", bundle: .module)
        case .straps:      return String(localized: "Straps", bundle: .module)
        case .weightVest:  return String(localized: "Weight vest", bundle: .module)
        case .chalk:       return String(localized: "Chalk", bundle: .module)
        }
    }

    public var sfSymbolName: String {
        switch self {
        case .belt:        return "oval.portrait"
        case .kneeSleeves: return "bandage"
        case .wristWraps:  return "bandage.fill"
        case .straps:      return "link"
        case .weightVest:  return "tshirt.fill"
        case .chalk:       return "sparkles"
        }
    }
}

/// Circumstances of the attempt (FR-004).
public enum PRContext: String, CaseIterable, Codable, Sendable {
    case fresh
    case inWod
    case competition

    public var displayName: String {
        switch self {
        case .fresh:       return String(localized: "Fresh", bundle: .module)
        case .inWod:       return String(localized: "In WOD", bundle: .module)
        case .competition: return String(localized: "Competition", bundle: .module)
        }
    }
}

/// A single PR Board result entry — the sole input of `PRResolver`.
/// `date` is the user-chosen day of the result; `createdAt` is the save
/// timestamp and breaks ties between same-day duplicates.
public struct PREntry: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let movementId: String
    public let date: Date
    public let createdAt: Date
    public let score: PRScoreValue
    /// nil when the movement does not support Rx/scaled.
    public let isRx: Bool?
    public let equipment: Set<PREquipment>
    public let rpe: Double?
    public let note: String?
    public let bodyWeightKg: Double?
    public let context: PRContext

    public init(
        id: UUID,
        movementId: String,
        date: Date,
        createdAt: Date,
        score: PRScoreValue,
        isRx: Bool? = nil,
        equipment: Set<PREquipment> = [],
        rpe: Double? = nil,
        note: String? = nil,
        bodyWeightKg: Double? = nil,
        context: PRContext = .fresh
    ) {
        self.id = id
        self.movementId = movementId
        self.date = date
        self.createdAt = createdAt
        self.score = score
        self.isRx = isRx
        self.equipment = equipment
        self.rpe = rpe
        self.note = note
        self.bodyWeightKg = bodyWeightKg
        self.context = context
    }
}
