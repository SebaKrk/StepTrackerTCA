//
//  PeerEvent.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 23/05/2026.
//

import Foundation

/// Event lifecycle peera w sesji peer-to-peer (Bluetooth Low Energy).
///
/// **Convention `peerID == nick`** zachowana z MC era: reducer `GymRoomFeature`
/// używa `peerID` z `.disconnected` jako klucz `state.athletes.remove(id:)`,
/// gdzie kluczem athletes jest nick (= `HRSamplePayload.nick`). BLE host session
/// emit'uje `.connected(peerID: nick, nick: nick)` po pierwszym otrzymanym payload
/// (czeka na nick — `CBCentral.identifier.uuidString` nie pasowałby do reducer key).
public enum PeerEvent: Sendable, Equatable {
    case connected(peerID: String, nick: String)
    case disconnected(peerID: String)
}
