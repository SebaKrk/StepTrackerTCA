//
//  ScanFinding+Message.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation
import SharedModels

extension ScanFinding {

    /// User-facing copy for the review card; SharedModels ships no string catalog.
    nonisolated var message: String {
        switch kind {
        case .emptyPlan:
            return String(localized: "No workout plan found in this photo.")
        case .emptyBlock:
            return String(localized: "This block has no movements.")
        case let .defaultTimeCapApplied(minutes):
            return String(localized: "No time cap on the board — \(minutes) min applied.")
        case let .emomCapNotMultiple(everySeconds):
            return String(localized: "The cap is not a whole number of \(everySeconds) s intervals.")
        case .forTimeWithoutCap:
            return String(localized: "For Time without a cap — a DNF cannot be recorded.")
        case let .loadTooHeavy(kilograms):
            return String(localized: "\(kilograms) kg looks like a misread load.")
        case .womenHeavierThanMen:
            return String(localized: "The women's load is heavier than the men's.")
        case let .unknownMovement(rawName):
            return String(localized: "\"\(rawName)\" is not in the exercise catalog — it will be saved under that name.")
        case let .uncertainField(field):
            return String(localized: "The reader was not sure about: \(fieldTitle(field)).")
        case .ladderAndRoundsBothSet:
            return String(localized: "Rep ladder and round count were both written — the ladder was kept.")
        case .duplicateBlockName:
            return String(localized: "Two blocks shared a name — a number was added.")
        }
    }

    /// Heading of the finding: block, or block and movement.
    nonisolated var title: String {
        exerciseName.map { "\(blockName) · \($0)" } ?? blockName
    }

    /// Schema field names as the athlete would call them.
    nonisolated private func fieldTitle(_ field: String) -> String {
        switch field {
        case "timeCapMin": return String(localized: "time cap")
        case "roundCount": return String(localized: "round count")
        case "repScheme": return String(localized: "rep ladder")
        case "movements": return String(localized: "the movements")
        case "notes": return String(localized: "the notes")
        case "alternatives": return String(localized: "the alternatives")
        case "everySec": return String(localized: "the interval")
        default: return field
        }
    }
}
