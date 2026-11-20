//
//  ScanFinding.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation

/// One thing to check on a scanned plan, tied to the block (and movement) it concerns.
public struct ScanFinding: Identifiable, Equatable, Sendable {

    /// Stable identity for the review list.
    public let id: UUID

    /// What was found.
    public let kind: ScanFindingKind

    /// `WorkoutSessionNew.id` of the block; nil when the finding concerns the whole plan.
    public let blockId: UUID?

    /// `ExerciseSession.id` of the movement; nil when the finding concerns the block.
    public let exerciseId: UUID?

    /// Block name at the time of the scan, for the list heading.
    public let blockName: String

    /// Movement name at the time of the scan; nil for block-level findings.
    public let exerciseName: String?

    /// User pressed "OK" on a `needsConfirmation` finding.
    public var isConfirmed: Bool

    public init(
        id: UUID = UUID(),
        kind: ScanFindingKind,
        blockId: UUID?,
        exerciseId: UUID? = nil,
        blockName: String,
        exerciseName: String? = nil,
        isConfirmed: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.blockId = blockId
        self.exerciseId = exerciseId
        self.blockName = blockName
        self.exerciseName = exerciseName
        self.isConfirmed = isConfirmed
    }

    /// Severity of the kind, exposed for filtering.
    public var severity: ScanFindingSeverity { kind.severity }

    /// Same block, movement and kind: a recomputed finding that carries over a confirmation.
    public func isSameIssue(as other: ScanFinding) -> Bool {
        blockId == other.blockId && exerciseId == other.exerciseId && kind == other.kind
    }

    /// Still blocks saving: a rule that has not passed, or a doubt the user has not closed.
    public var isOpen: Bool {
        switch severity {
        case .hard, .needsFix: return true
        case .needsConfirmation: return !isConfirmed
        case .info: return false
        }
    }
}
