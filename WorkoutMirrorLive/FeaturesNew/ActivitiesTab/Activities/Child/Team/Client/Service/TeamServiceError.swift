//
//  TeamServiceError.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 24/10/2026.
//

import Foundation

/// Failures of the Team backend that the UI reacts to differently than to a network error.
nonisolated enum TeamServiceError: Error, Equatable, Sendable {

    /// The scanned invite does not exist (wrong or deleted code).
    case inviteNotFound

    /// The invite was revoked or has expired.
    case inviteClosed

    /// A stored document is missing a field or has a wrong type.
    case malformedDocument(path: String)

    /// The owner tried to leave without naming a successor while the server still lists other members.
    case successorRequired
}

extension TeamServiceError: LocalizedError {

    var errorDescription: String? {
        switch self {
        case .inviteNotFound:
            return String(localized: "This invite does not exist.")
        case .inviteClosed:
            return String(localized: "This invite was closed or has expired.")
        case .malformedDocument:
            return String(localized: "The group data could not be read.")
        case .successorRequired:
            return String(localized: "The member list is still loading, so no one could take over the group. Try again in a moment.")
        }
    }
}
