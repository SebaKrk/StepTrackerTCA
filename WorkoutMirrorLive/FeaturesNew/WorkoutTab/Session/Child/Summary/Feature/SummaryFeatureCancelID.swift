//
//  SummaryFeatureCancelID.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 30/08/2025.
//

/// Identifiers used to cancel in-flight effects in `SummaryFeature`.
nonisolated enum SummaryFeatureCancelID: Hashable, Sendable {

    /// Cancels the listener observing workout session state changes.
    case sessionStateListener

    /// Cancels the retry loop that polls for workout summary availability.
    case retry
}
