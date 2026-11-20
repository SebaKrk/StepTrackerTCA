//
//  TeamInvite.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 24/10/2026.
//

import Foundation

/// A QR invite into a group; one invite can be scanned by many people.
public struct TeamInvite: Identifiable, Equatable, Codable, Sendable {

    /// Unguessable invite id carried in the QR code.
    public let id: String

    /// Group the invite leads to.
    public let groupId: String

    /// Group name copied at creation — a non-member cannot read the group itself.
    public let groupName: String

    /// Member who created the invite.
    public let createdByUid: String

    /// Name of that member, shown on the invitation card.
    public let createdByName: String

    /// Creation time.
    public let createdAt: Date

    /// After this moment the invite no longer lets anyone join.
    public let expiresAt: Date

    /// Set once the invite has been withdrawn.
    public let isRevoked: Bool

    public init(
        id: String,
        groupId: String,
        groupName: String,
        createdByUid: String,
        createdByName: String,
        createdAt: Date,
        expiresAt: Date,
        isRevoked: Bool
    ) {
        self.id = id
        self.groupId = groupId
        self.groupName = groupName
        self.createdByUid = createdByUid
        self.createdByName = createdByName
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.isRevoked = isRevoked
    }

    /// Whether the invite still lets someone join at `now`.
    public func isOpen(at now: Date) -> Bool {
        !isRevoked && expiresAt > now
    }
}
