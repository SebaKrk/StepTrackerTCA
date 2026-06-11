//
//  GymRoomFeature+CancelID.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 23/05/2026.
//

import Foundation

extension GymRoomFeature {

    nonisolated enum GymRoomCancelID: Hashable, Sendable {

        /// Subskrypcja `peerMirrorClient.peerEventsStream()`.
        case peerEvents

        /// Subskrypcja `peerMirrorClient.samplesStream()`.
        case samples
    }
}
