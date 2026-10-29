//
//  TeamMember.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 24/10/2026.
//

import Foundation

/// A member of a group, as other members see them.
public struct TeamMember: Identifiable, Equatable, Codable, Sendable {

    /// Account id of the member.
    public let uid: String

    /// Name shown to other members.
    public let displayName: String

    /// Time the member joined the group.
    public let joinedAt: Date

    public var id: String { uid }

    public init(uid: String, displayName: String, joinedAt: Date) {
        self.uid = uid
        self.displayName = displayName
        self.joinedAt = joinedAt
    }
}
