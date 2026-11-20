//
//  TeamGroup.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 24/10/2026.
//

import Foundation

/// A private group whose members share daily plans and compare results.
public struct TeamGroup: Identifiable, Equatable, Codable, Sendable {

    /// Document id of the group.
    public let id: String

    /// Name shown in the group list (3–40 characters).
    public let name: String

    /// Account that created the group — the only one who may rename or delete it.
    public let ownerUid: String

    /// Creation time.
    public let createdAt: Date

    /// Members in the group; `nil` for groups created before the counter existed.
    public let memberCount: Int?

    /// The most recently published plan with its result count; `nil` when none was published.
    public let lastPlan: TeamGroupPlanSummary?

    public init(
        id: String,
        name: String,
        ownerUid: String,
        createdAt: Date,
        memberCount: Int? = nil,
        lastPlan: TeamGroupPlanSummary? = nil
    ) {
        self.id = id
        self.name = name
        self.ownerUid = ownerUid
        self.createdAt = createdAt
        self.memberCount = memberCount
        self.lastPlan = lastPlan
    }
}
