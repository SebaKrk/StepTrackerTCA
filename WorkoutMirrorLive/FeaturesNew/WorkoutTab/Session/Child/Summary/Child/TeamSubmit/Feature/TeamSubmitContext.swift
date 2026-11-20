//
//  TeamSubmitContext.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import Foundation
import SharedModels

/// Everything the "Send to group" row needs, read once when the Summary opens.
struct TeamSubmitContext: Equatable, Sendable {

    /// Account id of the current user.
    let uid: String

    /// Name the group sees.
    let displayName: String

    /// Group name for the row title; `nil` when the group is no longer accessible.
    let groupName: String?

    /// The group's plan for that day; `nil` when it was removed.
    let plan: TeamPlan?

    /// Entry submitted earlier for the same plan — editing keeps its first submission time.
    let existingEntry: TeamEntry?
}
