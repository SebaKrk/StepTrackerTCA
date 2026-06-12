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
///
/// **Lifecycle dla hosta (iPad)**:
/// - `.connected` — nowy peer (lub reconnect z service-side detection został wcześniej
///   przemapowany na `.reconnected`)
/// - `.suspended` — peer BLE-unsubscribed; kafelek w UI wchodzi w stan `reconnecting`,
///   host czeka 10s grace period (w `PeerMirrorService.disconnectingPeers`)
/// - `.reconnected` — w grace window przyszedł nowy payload z **tym samym `deviceID`**;
///   service cancel'uje timer i emit'uje ten event (NIE `.connected`)
/// - `.disconnected` — final removal (grace timeout, host `stop()`, lub explicit reject)
///
/// **Lifecycle dla peer'a (iPhone)**: tylko `.connected` / `.disconnected` — peer-side
/// nie używa buffering'u (host orchestrates), tylko binary connection state z perspektywy peer'a.
public enum PeerEvent: Sendable, Equatable {
    case connected(deviceID: UUID, nick: String)
    case suspended(deviceID: UUID, nick: String)
    case reconnected(deviceID: UUID, nick: String)
    case disconnected(deviceID: UUID)
}
