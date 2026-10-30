//
//  ManageGroupCancelID.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 30/10/2026.
//

import Foundation

/// Cancel identifiers of `ManageGroupFeature` long-running effects.
nonisolated enum ManageGroupCancelID: Hashable, Sendable {

    /// Live member list.
    case members
}
