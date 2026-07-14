//
//  BLEServiceConstants.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 2026-05-25.
//

import CoreBluetooth

/// Stałe GATT dla peer-to-peer transportu Gym Room PoC (subtask IPAD-0087-F).
///
/// UUIDs wygenerowane jednorazowo przez `uuidgen` — NIGDY nie regenerować runtime
/// (peripheral i central muszą zgadzać się co do wartości; deterministyczne stałe).
///
/// `nonisolated(unsafe)` bo `CBUUID` nie jest oznaczone `Sendable` przez Apple
/// (legacy framework), choć w praktyce jest immutable value — false positive Swift 6.
///
/// Reference: WWDC22 #110339 — "Boost performance and security in Core Bluetooth".
public enum BLEServiceConstants {

    /// Główne GATT service publikowane przez iPada (peripheral) i skanowane przez iPhone'y (central).
    /// Custom 128-bit UUID — nie kolizjonuje z BT SIG standard services (np. Heart Rate `0x180D`).
    nonisolated(unsafe) public static let gymRoomServiceUUID = CBUUID(string: "88196275-D0C1-46CA-BB8B-DD032A54EAAE")

    /// Characteristic do streamingu HR samples z iPhone → iPad.
    /// Property: `writeWithoutResponse` — idempotent stream (zgubiony sample OK, następny przyjdzie za ~2s).
    nonisolated(unsafe) public static let hrStreamCharacteristicUUID = CBUUID(string: "BF244FA3-3D12-4933-BD50-478B85EC6CB2")

    /// Characteristic do read-once metadata o sali (`roomName`, `sessionId`, `capacity`).
    /// Property: `read` (jednorazowe pobranie przy discovery, low traffic).
    nonisolated(unsafe) public static let discoveryInfoCharacteristicUUID = CBUUID(string: "34EF3094-EFAB-41D3-981B-0498DE7E3ED2")
}
