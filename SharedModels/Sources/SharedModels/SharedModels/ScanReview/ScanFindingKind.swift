//
//  ScanFindingKind.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation

/// What the validator found. The app turns each case into user-facing copy.
public enum ScanFindingKind: Equatable, Sendable {

    /// The board holds no training blocks.
    case emptyPlan

    /// A training block has no movements.
    case emptyBlock

    /// A timed block had no cap on the board; the type's default was applied.
    case defaultTimeCapApplied(minutes: Int)

    /// An EMOM cap that is not a whole number of its cadence.
    case emomCapNotMultiple(everySeconds: Int)

    /// A For Time block without a cap; DNF cannot be recorded without one.
    case forTimeWithoutCap

    /// A load the reader almost certainly got wrong.
    case loadTooHeavy(kilograms: Int)

    /// A men/women pair where the women's load is the heavier one.
    case womenHeavierThanMen

    /// The movement name did not match the exercise catalog.
    case unknownMovement(rawName: String)

    /// The model marked this field as read without confidence.
    case uncertainField(field: String)

    /// Both a rep ladder and a round count were written; the round count was dropped.
    case ladderAndRoundsBothSet

    /// Two blocks shared a name; a number was appended to the later one.
    case duplicateBlockName

    /// Severity follows from the kind, so the two can never disagree.
    public var severity: ScanFindingSeverity {
        switch self {
        case .emptyPlan, .emptyBlock:
            return .hard
        case .emomCapNotMultiple, .forTimeWithoutCap, .loadTooHeavy, .womenHeavierThanMen:
            return .needsFix
        // The catalog may simply lack the movement ("any machine"), so keeping the raw name is a valid answer.
        case .defaultTimeCapApplied, .uncertainField, .unknownMovement:
            return .needsConfirmation
        case .ladderAndRoundsBothSet, .duplicateBlockName:
            return .info
        }
    }
}
