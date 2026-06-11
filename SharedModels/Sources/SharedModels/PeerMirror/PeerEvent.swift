//
//  PeerEvent.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 23/05/2026.
//

import Foundation

/// Event lifecycle peera w sesji peer-to-peer (Bluetooth Low Energy).
///
/// **Primary key = `deviceID`** (per-install UUID z `HRSamplePayload`). Host indexuje
/// `connectedCentrals` po `deviceID`, dzięki czemu reconnect detection działa
/// niezależnie od `CBPeripheral.identifier` (Apple rotuje per BLE connection cycle).
/// `nick` jest tylko display name — może się powtarzać między peerami.
public enum PeerEvent: Sendable, Equatable {
    case connected(deviceID: UUID, nick: String)
    case disconnected(deviceID: UUID)
}
