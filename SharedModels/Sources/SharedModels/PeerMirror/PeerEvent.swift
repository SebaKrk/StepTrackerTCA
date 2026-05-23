//
//  PeerEvent.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 23/05/2026.
//

import Foundation

/// Event lifecycle peera w sesji MultipeerConnectivity.
///
/// `peerID` to surowy `displayName` z `MCPeerID` — używany jako stable id w UI.
/// `.connected` niesie też `nick` z displayName (= nick athlety w Proof of Concept).
public enum PeerEvent: Sendable, Equatable {
    case connected(peerID: String, nick: String)
    case disconnected(peerID: String)
}
