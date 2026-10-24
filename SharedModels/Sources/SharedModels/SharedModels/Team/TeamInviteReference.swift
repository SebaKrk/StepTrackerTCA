//
//  TeamInviteReference.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 24/10/2026.
//

import Foundation

/// Where a scanned invite code points.
public struct TeamInviteReference: Equatable, Sendable {

    /// Group the invite belongs to.
    public let groupId: String

    /// Invite id within that group.
    public let inviteId: String

    public init(groupId: String, inviteId: String) {
        self.groupId = groupId
        self.inviteId = inviteId
    }
}
