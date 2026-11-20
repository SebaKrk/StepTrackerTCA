//
//  GroupLeaderboardCancelID.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import Foundation

/// Cancel identifiers of `GroupLeaderboardFeature` long-running effects.
nonisolated enum GroupLeaderboardCancelID: Hashable, Sendable {

    /// Live entries of the shown day's plan.
    case dayEntries

    /// One-shot read of the shown week.
    case week
}
