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

        /// Timer co ~2s emitujący fake HR samples (Proof of Concept).
        /// TODO IPAD-0099: zastąp real WCSession HR stream subscription.
        case hrTimer
    }
}
