//
//  InvitationPreviewFailure.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import Foundation

/// Why a scanned code cannot be shown as an invitation.
nonisolated enum InvitationPreviewFailure: Equatable, Sendable {

    /// The code is something else — a plan, a GymRoom class, a website.
    case notAnInvite

    /// The invite does not exist.
    case notFound

    /// The invite was revoked or has expired.
    case closed

    /// Network or server error.
    case unavailable

    var title: String {
        switch self {
        case .notAnInvite: String(localized: "Not a Group Invite")
        case .notFound: String(localized: "Invite Not Found")
        case .closed: String(localized: "Invite No Longer Valid")
        case .unavailable: String(localized: "Something went wrong")
        }
    }

    var message: String {
        switch self {
        case .notAnInvite: String(localized: "This QR code doesn't lead to a Team group.")
        case .notFound: String(localized: "Ask the person who invited you for a new code.")
        case .closed: String(localized: "The code expired or was revoked. Ask for a new one.")
        case .unavailable: String(localized: "Check your connection and try again.")
        }
    }
}
