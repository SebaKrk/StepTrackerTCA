//
//  JoinLiveClassFeature+CancelID.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 23/05/2026.
//

import Foundation

extension JoinLiveClassFeature {

    nonisolated enum JoinLiveClassCancelID: Hashable, Sendable {

        /// Subskrypcja `peerMirrorClient.peerEventsStream()`.
        case peerEvents

        /// Subskrypcja `watchConnectivityManager.incomingWorkoutEventStream`
        /// filtrowana do `.hrReading` events z Apple Watcha.
        case hrStream
    }
}
