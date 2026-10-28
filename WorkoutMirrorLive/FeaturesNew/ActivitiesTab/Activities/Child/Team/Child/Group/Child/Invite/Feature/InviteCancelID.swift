//
//  InviteCancelID.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import Foundation

/// Cancel identifiers of `InviteFeature` long-running effects.
nonisolated enum InviteCancelID: Hashable, Sendable {

    /// Live list of people who scanned the current code.
    case scans
}
