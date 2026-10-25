//
//  SummaryTeamSubmission.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import Foundation
import SharedModels

/// What the Summary captures on save to post a result to a Team group.
struct SummaryTeamSubmission: Sendable {

    /// Group of the plan.
    let groupId: String

    /// The group's daily plan.
    let plan: TeamPlan

    /// Account, name and any earlier entry.
    let context: TeamSubmitContext

    /// Rx or Scaled.
    let division: BoardDivision

    /// The user agreed to share kcal.
    let includeKcal: Bool

    /// Scored block of the local copy — its type decides how a capped For Time is read.
    let scoredBlock: WorkoutSessionNew

    /// Score entered for that block; `nil` when the block was not scored.
    let scoredResult: WodScoreResult?
}
