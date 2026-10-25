//
//  TeamRecipientRecord.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 24/10/2026.
//

import Foundation
import SharedModels

/// A `recipients/{uid}` document read from a snapshot, before its invite is fetched.
nonisolated struct TeamRecipientRecord: Sendable {

    /// Invite the document belongs to; `nil` when the path is not where recipients live.
    let reference: TeamInviteReference?

    /// Account id of the person who scanned.
    let uid: String

    /// Name of that person.
    let displayName: String

    /// Stored decision.
    let status: TeamRecipientStatus

    /// Time of the latest scan.
    let scannedAt: Date

    /// Time of the decision; `nil` while pending.
    let respondedAt: Date?

    /// Invitation for the given invite.
    func invitation(with invite: TeamInvite) -> TeamInvitation {
        TeamInvitation(
            invite: invite,
            recipientUid: uid,
            recipientName: displayName,
            status: status,
            scannedAt: scannedAt,
            respondedAt: respondedAt
        )
    }
}
