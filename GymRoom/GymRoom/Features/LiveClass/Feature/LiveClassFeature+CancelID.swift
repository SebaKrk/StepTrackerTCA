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

        /// Timer effect dla batch persistence HR samples (co 30s flush buffer → BLOB).
        /// Cancellowany na `confirmEnd` żeby zatrzymać write'y do bazy po End class.
        case persistenceTimer
    }
}
