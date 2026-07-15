//
//  ClassRecapPayload.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 15/07/2026.
//

import Foundation

/// Per-athlete class result the host (iPad) sends to each connected participant at
/// class end, over BLE (`hrCharacteristic`, prefixed `0xFE` to distinguish from the
/// HR-JSON stream and the `0xFF` class-ended sentinel).
///
/// Deliberately minimal — it carries only what the participant CANNOT know locally:
/// their `place`, the `participantCount`, and the class coordinates for the recap map.
/// `gymName` (from the scanned QR) and the class points (from the on-device
/// window-scoped counter, IOS-00104-B) are added by the participant when it stores the
/// pending recap, so they never travel over BLE.
///
/// `deviceID` addresses the recap: the host sends per-device, and the peer also checks
/// `deviceID == mine` as a sanity guard.
public struct ClassRecapPayload: Codable, Sendable, Equatable {

    /// Per-install participant identifier (matches `HRSamplePayload.deviceID`).
    public let deviceID: UUID

    /// The class-session instance this result belongs to (links to `ClassSessionRecord`).
    public let classSessionId: UUID

    /// Athlete's finishing place in the class ranking (1-based).
    public let place: Int

    /// Total number of participants in the class (the "M" in "place N of M").
    public let participantCount: Int

    /// Class location coordinates for the recap map — `nil` when the class had no
    /// geocoded address (location typed freehand or predating the address feature).
    public let latitude: Double?
    public let longitude: Double?

    public init(
        deviceID: UUID,
        classSessionId: UUID,
        place: Int,
        participantCount: Int,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.deviceID = deviceID
        self.classSessionId = classSessionId
        self.place = place
        self.participantCount = participantCount
        self.latitude = latitude
        self.longitude = longitude
    }
}
