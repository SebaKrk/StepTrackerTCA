//
//  SensorDisconnectReason.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 22/07/2026.
//

import Foundation

/// Why the peer's BLE heart-rate strap dropped, mapped from the CoreBluetooth
/// disconnect error and forwarded to the host in `HRSamplePayload`. `String`
/// raw value so the host can log it directly.
///
/// A clean, app-requested disconnect (workout end) is NOT represented — the
/// payload field stays `nil` in that case, and a `nil` while stale means the
/// strap went silent without any BLE disconnect (likely skin contact).
public enum SensorDisconnectReason: String, Codable, Sendable, Equatable {

    /// CoreBluetooth `connectionTimeout` (#6) — link supervision timeout: the
    /// strap went out of range or the signal was lost.
    case outOfRange

    /// CoreBluetooth `peripheralDisconnected` (#7) — the strap itself ended the
    /// link: powered off, went to sleep, or the battery died.
    case deviceOff

    /// Any other CoreBluetooth disconnect error (pairing / encryption / …).
    case other
}
