//
//  TeamInvitation.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 24/10/2026.
//

import Foundation

/// One person's copy of an invite they scanned.
public struct TeamInvitation: Identifiable, Equatable, Codable, Sendable {

    /// Invite the person scanned.
    public let invite: TeamInvite

    /// Account id of the person.
    public let recipientUid: String

    /// Name of the person, shown on the sender's list.
    public let recipientName: String

    /// Stored decision.
    public let status: TeamRecipientStatus

    /// Time of the (latest) scan.
    public let scannedAt: Date

    /// Time of the decision; `nil` while pending.
    public let respondedAt: Date?

    public var id: String { "\(invite.groupId)/\(invite.id)/\(recipientUid)" }

    public init(
        invite: TeamInvite,
        recipientUid: String,
        recipientName: String,
        status: TeamRecipientStatus,
        scannedAt: Date,
        respondedAt: Date?
    ) {
        self.invite = invite
        self.recipientUid = recipientUid
        self.recipientName = recipientName
        self.status = status
        self.scannedAt = scannedAt
        self.respondedAt = respondedAt
    }

    /// Status to display at `now`; expiry and revocation only matter while undecided.
    public func state(at now: Date) -> TeamInvitationState {
        switch status {
        case .accepted:
            return .accepted
        case .declined:
            return .declined
        case .pending:
            if invite.isRevoked { return .revoked }
            if invite.expiresAt <= now { return .expired }
            return .pending
        }
    }
}
