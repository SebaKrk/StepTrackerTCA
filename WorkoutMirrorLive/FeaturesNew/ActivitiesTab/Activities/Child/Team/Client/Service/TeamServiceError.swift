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
}
