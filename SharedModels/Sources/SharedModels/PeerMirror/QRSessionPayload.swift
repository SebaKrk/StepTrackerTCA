//
//  QRSessionPayload.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 11/06/2026.
//

import Foundation

/// Payload kodowany w QR code'zie na iPadzie + skanowany na iPhone'ie.
///
/// Generowany na `LiveClassFeature.view(.startTapped)` (token = `UUID()`),
/// invalid'owany na `.endTapped`. Encoded jako JSON UTF-8 → `CIFilter.qrCodeGenerator`.
///
/// **Warstwy identity**:
/// - `token` — per-class (rotowany na każdym Start). Peer wysyła go w
///   `HRSamplePayload.sessionToken` (subtask C3), host validate'uje w `didReceiveWrite`.
///   Stary token (po End→Start) = reject.
/// - `iPadID` — per-install UUID hosta. Sanity check po stronie peer'a
///   ("scanned different iPad than last time") + debug. Future multi-room (IPAD-0094).
/// - `gymName` — display name sali ("Iron Den" etc.) widoczny dla peer'a.
/// - `createdAt` — expiry sanity check (peer może sprawdzić np. >4h = expired).
///   Host **nie** sprawdza expiry — token rotuje per-class, więc stary token i tak reject.
public struct QRSessionPayload: Codable, Sendable, Equatable {

    public let token: UUID
    public let iPadID: UUID
    public let gymName: String
    public let createdAt: Date

    public init(
        token: UUID,
        iPadID: UUID,
        gymName: String,
        createdAt: Date = Date()
    ) {
        self.token = token
        self.iPadID = iPadID
        self.gymName = gymName
        self.createdAt = createdAt
    }
}
