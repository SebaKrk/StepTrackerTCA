//
//  GroupCancelID.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import Foundation

/// Cancel identifiers of `GroupFeature` long-running effects.
nonisolated enum GroupCancelID: Hashable, Sendable {

    /// Live member list.
    case members

    /// Live plan of the selected day.
    case dayPlan
}
