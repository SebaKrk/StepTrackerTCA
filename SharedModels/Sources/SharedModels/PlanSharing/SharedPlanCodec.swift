//
//  SharedPlanCodec.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 13/07/2026.
//

import Foundation

public enum SharedPlanCodecError: Error, Equatable {
    case malformed
    case unsupportedVersion(found: Int, supported: Int)
}

/// Encodes/decodes a `SharedPlanPayload` as a compact string: JSON → zlib → base64url.
///
/// zlib compression is what makes most plans fit in a QR code — plan JSON is
/// highly repetitive (keys) and compresses ~60-70%. base64url (not plain base64)
/// keeps the string URL-safe so the same encoding can back a future share link.
public enum SharedPlanCodec {

    public static let currentSchemaVersion = 1

    /// Byte budget for a payload we are willing to render as a QR code.
    /// Below the ECC-M version-40 max, with margin for reliable phone-screen scans.
    /// Tune against real plans; oversized plans fall back to the file channel.
    public static let maxQRPayloadBytes = 1500

    public static func encode(plan: TrainingSession, exportedAt: Date) throws -> String {
        try encode(
            SharedPlanPayload(
                schemaVersion: currentSchemaVersion,
                exportedAt: exportedAt,
                plan: plan
            )
        )
    }

    public static func encode(_ payload: SharedPlanPayload) throws -> String {
        let json = try encoder.encode(payload)
        let compressed = try (json as NSData).compressed(using: .zlib) as Data
        return base64url(from: compressed)
    }

    public static func decode(_ string: String) throws -> SharedPlanPayload {
        guard let compressed = data(fromBase64url: string),
              let json = try? (compressed as NSData).decompressed(using: .zlib) as Data else {
            throw SharedPlanCodecError.malformed
        }
        // Check the version FIRST, before decoding the full plan body. A newer
        // schema may have changed `TrainingSession`'s shape — decoding it would
        // throw and (via try?) collapse into `.malformed`, making the
        // `unsupportedVersion` path unreachable. Probe just the version field.
        if let probe = try? decoder.decode(VersionProbe.self, from: json),
           probe.schemaVersion > currentSchemaVersion {
            throw SharedPlanCodecError.unsupportedVersion(
                found: probe.schemaVersion,
                supported: currentSchemaVersion
            )
        }
        guard let payload = try? decoder.decode(SharedPlanPayload.self, from: json) else {
            throw SharedPlanCodecError.malformed
        }
        return payload
    }

    /// Minimal shape to read only the version before attempting a full decode.
    private struct VersionProbe: Decodable {
        let schemaVersion: Int
    }

    public static func fitsInQR(_ encoded: String) -> Bool {
        encoded.utf8.count <= maxQRPayloadBytes
    }

    // MARK: - Implementation

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private static func base64url(from data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func data(fromBase64url string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder > 0 {
            base64.append(String(repeating: "=", count: 4 - remainder))
        }
        return Data(base64Encoded: base64)
    }
}
