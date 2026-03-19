//
//  LiveSessionFeature+StopwatchID.swift
//  WorkoutMirrorLive
//

extension LiveSessionFeature {

    /// Typed identifiers for `StopwatchFeature` instances owned by `LiveSessionFeature`.
    /// Used to namespace `CancelID`s so that stopping one stopwatch doesn't affect the other.
    enum StopwatchID: Hashable {
        /// The user-facing stopwatch opened via the toolbar button.
        case user
        /// The stopwatch managing the active phase timer.
        case phase
    }

}
