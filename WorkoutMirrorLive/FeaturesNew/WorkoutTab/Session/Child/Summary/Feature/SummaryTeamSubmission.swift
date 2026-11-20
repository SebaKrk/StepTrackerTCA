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

    /// Results entered for the plan's scored blocks, keyed by the group plan's block ids.
    let scores: [UUID: BoardScore]
}
