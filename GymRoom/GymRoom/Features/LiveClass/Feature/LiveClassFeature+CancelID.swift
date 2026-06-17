//
//  LiveClassFeature+CancelID.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 23/05/2026.
//

import Foundation

extension LiveClassFeature {

    nonisolated enum LiveClassCancelID: Hashable, Sendable {

        /// Subskrypcja `peerMirrorClient.peerEventsStream()`.
        case peerEvents

        /// Subskrypcja `peerMirrorClient.samplesStream()`.
        case samples
    }
}
