//
//  StopwatchFeature+CancelID.swift
//  WorkoutMirrorLive
//

extension StopwatchFeature {

    /// Cancel identifiers used by `StopwatchFeature` effects.
    /// `instanceID` namespaces the ID so multiple instances in one Store don't collide.
    nonisolated enum CancelID: Hashable, Sendable {

        /// Identifies the tick timer effect started on `.view(.start)`.
        case timer(AnyHashable)

    }

}
