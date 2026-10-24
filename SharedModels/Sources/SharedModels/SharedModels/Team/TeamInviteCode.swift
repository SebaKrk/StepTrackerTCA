//
//  TeamInviteCode.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 24/10/2026.
//

import Foundation

/// Text carried by an invite QR code: `mfj://team/invite/{groupId}/{inviteId}`.
public enum TeamInviteCode {

    private static let prefix = "mfj://team/invite/"

    /// Builds the QR text for an invite.
    public static func encode(groupId: String, inviteId: String) -> String {
        prefix + groupId + "/" + inviteId
    }

    /// Reads a scanned QR text; any other code (a plan, a GymRoom class) gives `nil`.
    public static func decode(_ raw: String) -> TeamInviteReference? {
        guard raw.hasPrefix(prefix) else { return nil }
        let parts = raw.dropFirst(prefix.count).split(separator: "/", omittingEmptySubsequences: false)
        guard parts.count == 2, parts.allSatisfy(isDocumentId) else { return nil }
        return TeamInviteReference(groupId: String(parts[0]), inviteId: String(parts[1]))
    }

    private static func isDocumentId(_ text: Substring) -> Bool {
        !text.isEmpty
            && text.count <= 64
            && text.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-" || $0 == "_") }
    }
}
