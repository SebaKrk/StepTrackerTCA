//
//  TeamCancelID.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import Foundation

/// Cancel identifiers of `TeamFeature` long-running effects.
nonisolated enum TeamCancelID: Hashable, Sendable {

    /// Sign-in followed by the live list of the user's groups.
    case groups

    /// Live list of invites the user scanned.
    case invitations

    /// One-shot read of the user's results for today's plans.
    case myEntries

    /// One-shot re-read of the groups (pull to refresh, return to the tab).
    case refresh
}
