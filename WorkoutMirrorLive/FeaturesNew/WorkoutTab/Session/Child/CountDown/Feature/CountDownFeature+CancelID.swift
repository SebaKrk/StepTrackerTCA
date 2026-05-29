//
//  CountDownFeature+CancelID.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 2026-05-29.
//

import Foundation

extension CountDownFeature {

    /// IDs used for cancelling timer effects. `nonisolated` so the enum is not subject
    /// to `@MainActor` propagation from the project's default isolation
    /// (`defaultIsolation(MainActor.self)`), which would make synthesized `Hashable`
    /// conformance actor-isolated and conflict with the `Sendable` requirement of
    /// `cancellable(id:)`. Matches the convention used by other CancelID enums in
    /// the project (`GymRoomCancelID`, `JoinLiveClassCancelID`, `StatsFeatureCancelID`).
    nonisolated enum CancelID: Hashable, Sendable {
        case timer
        /// Pulse animation timer (600 ms cadence) for the `.waitingForWatch` ring.
        case pulseTimer
    }
}
