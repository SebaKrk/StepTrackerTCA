//
//  TeamClient.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 24/10/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

// MARK: - Client

/// Groups, invites, daily plans and entries of the Team tab. The only way the app reaches the backend.
struct TeamClient: Sendable {

    // MARK: - Account

    /// Signs in anonymously when needed and returns the account id.
    var ensureSignedIn: @Sendable () async throws -> String

    // MARK: - Groups

    /// Emits the groups the current account belongs to, again after every membership change.
    var observeMyGroups: @Sendable () -> AsyncThrowingStream<[TeamGroup], Error>

    /// Creates a private group with the current account as its owner and first member.
    var createGroup: @Sendable (_ name: String, _ displayName: String) async throws -> TeamGroup

    /// Removes the current account from a group.
    var leaveGroup: @Sendable (_ groupId: String) async throws -> Void

    /// Returns the members of a group, earliest first.
    var members: @Sendable (_ groupId: String) async throws -> [TeamMember]

    // MARK: - Invites

    /// Creates a QR invite valid for seven days.
    var createInvite: @Sendable (_ group: TeamGroup, _ createdByName: String) async throws -> TeamInvite

    /// Withdraws an invite so it no longer lets anyone join.
    var revokeInvite: @Sendable (_ groupId: String, _ inviteId: String) async throws -> Void

    /// Records a scanned invite for the current account and returns its invitation (pending, or the earlier decision).
    var receiveInvite: @Sendable (_ reference: TeamInviteReference, _ displayName: String) async throws -> TeamInvitation

    /// Accepts (joins the group) or declines an invitation.
    var respondToInvite: @Sendable (_ invitation: TeamInvitation, _ accept: Bool) async throws -> Void

    /// Emits every invite the current account has scanned, newest first.
    var observeMyInvitations: @Sendable () -> AsyncThrowingStream<[TeamInvitation], Error>

    /// Emits who scanned an invite and what they decided.
    var observeSentInvitations: @Sendable (_ groupId: String, _ inviteId: String) -> AsyncThrowingStream<[TeamInvitation], Error>

    // MARK: - Plans and entries

    /// Publishes a group's plan for the day in `plan.id`.
    var publishPlan: @Sendable (_ groupId: String, _ plan: TeamPlan) async throws -> Void

    /// Returns the group's plan for a day, or `nil` when none was published.
    var plan: @Sendable (_ groupId: String, _ day: String) async throws -> TeamPlan?

    /// Saves the current account's entry for a day, replacing an earlier one.
    var submitEntry: @Sendable (_ groupId: String, _ day: String, _ entry: TeamEntry) async throws -> Void

    /// Emits all entries for a day, again after every change.
    var observeDayEntries: @Sendable (_ groupId: String, _ day: String) -> AsyncThrowingStream<[TeamEntry], Error>

    /// Returns entries for each day that had a plan; days without a plan have no key.
    var weekEntries: @Sendable (_ groupId: String, _ days: [String]) async throws -> [String: [TeamEntry]]
}

// MARK: - DependencyValues

extension DependencyValues {
    var teamClient: TeamClient {
        get { self[TeamClientKey.self] }
        set { self[TeamClientKey.self] = newValue }
    }
}

// MARK: - DependencyKey

private enum TeamClientKey: DependencyKey {

    static let liveValue: TeamClient = {
        let service = TeamService()
        return TeamClient(
            ensureSignedIn: { try await service.ensureSignedIn() },
            observeMyGroups: { service.observeMyGroups() },
            createGroup: { try await service.createGroup(name: $0, displayName: $1) },
            leaveGroup: { try await service.leaveGroup(groupId: $0) },
            members: { try await service.members(groupId: $0) },
            createInvite: { try await service.createInvite(group: $0, createdByName: $1) },
            revokeInvite: { try await service.revokeInvite(groupId: $0, inviteId: $1) },
            receiveInvite: { try await service.receiveInvite(reference: $0, displayName: $1) },
            respondToInvite: { try await service.respondToInvite($0, accept: $1) },
            observeMyInvitations: { service.observeMyInvitations() },
            observeSentInvitations: { service.observeSentInvitations(groupId: $0, inviteId: $1) },
            publishPlan: { try await service.publishPlan(groupId: $0, plan: $1) },
            plan: { try await service.plan(groupId: $0, day: $1) },
            submitEntry: { try await service.submitEntry(groupId: $0, day: $1, entry: $2) },
            observeDayEntries: { service.observeDayEntries(groupId: $0, day: $1) },
            weekEntries: { try await service.weekEntries(groupId: $0, days: $1) }
        )
    }()

    static var testValue: TeamClient {
        TeamClient(
            ensureSignedIn: unimplemented("TeamClient.ensureSignedIn"),
            observeMyGroups: unimplemented("TeamClient.observeMyGroups", placeholder: .finished),
            createGroup: unimplemented("TeamClient.createGroup"),
            leaveGroup: unimplemented("TeamClient.leaveGroup"),
            members: unimplemented("TeamClient.members"),
            createInvite: unimplemented("TeamClient.createInvite"),
            revokeInvite: unimplemented("TeamClient.revokeInvite"),
            receiveInvite: unimplemented("TeamClient.receiveInvite"),
            respondToInvite: unimplemented("TeamClient.respondToInvite"),
            observeMyInvitations: unimplemented("TeamClient.observeMyInvitations", placeholder: .finished),
            observeSentInvitations: unimplemented("TeamClient.observeSentInvitations", placeholder: .finished),
            publishPlan: unimplemented("TeamClient.publishPlan"),
            plan: unimplemented("TeamClient.plan"),
            submitEntry: unimplemented("TeamClient.submitEntry"),
            observeDayEntries: unimplemented("TeamClient.observeDayEntries", placeholder: .finished),
            weekEntries: unimplemented("TeamClient.weekEntries")
        )
    }

    // Previews never touch Firebase — it is not configured in the preview process.
    static var previewValue: TeamClient {
        TeamClient(
            ensureSignedIn: { "preview-uid" },
            observeMyGroups: { .finished },
            createGroup: { name, _ in TeamGroup(id: "preview-group", name: name, ownerUid: "preview-uid", createdAt: .now) },
            leaveGroup: { _ in },
            members: { _ in [] },
            createInvite: { group, name in
                TeamInvite(
                    id: "preview-invite",
                    groupId: group.id,
                    groupName: group.name,
                    createdByUid: "preview-uid",
                    createdByName: name,
                    createdAt: .now,
                    expiresAt: .now.addingTimeInterval(7 * 24 * 60 * 60),
                    isRevoked: false
                )
            },
            revokeInvite: { _, _ in },
            receiveInvite: { _, _ in throw TeamServiceError.inviteNotFound },
            respondToInvite: { _, _ in },
            observeMyInvitations: { .finished },
            observeSentInvitations: { _, _ in .finished },
            publishPlan: { _, _ in },
            plan: { _, _ in nil },
            submitEntry: { _, _, _ in },
            observeDayEntries: { _, _ in .finished },
            weekEntries: { _, _ in [:] }
        )
    }
}

// MARK: - Helpers

private extension AsyncThrowingStream where Failure == Error {
    /// A stream that ends immediately without values.
    static var finished: Self {
        Self { $0.finish() }
    }
}
