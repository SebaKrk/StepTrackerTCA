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

    /// Reads the user's groups once — pull to refresh and returning to the tab.
    var myGroups: @Sendable () async throws -> [TeamGroup]

    /// Creates a private group with the current account as its owner and first member.
    var createGroup: @Sendable (_ name: String, _ displayName: String) async throws -> TeamGroup

    /// Removes the current account from a group. A leaving owner passes `successorUid` (the longest-standing
    /// member from the live list); with none, the group is deleted only if the server confirms the owner is alone.
    var leaveGroup: @Sendable (_ groupId: String, _ successorUid: String?) async throws -> Void

    /// Renames the group (owner only, by the rules).
    var renameGroup: @Sendable (_ groupId: String, _ name: String) async throws -> Void

    /// Hands the group to another member (owner only, by the rules).
    var transferOwnership: @Sendable (_ groupId: String, _ uid: String) async throws -> Void

    /// Removes a member, closes the group's open invite codes and drops the member's scans (owner only).
    var removeMember: @Sendable (_ groupId: String, _ uid: String) async throws -> Void

    /// Deletes the group with its members, invites, plans and results (owner only).
    var deleteGroup: @Sendable (_ groupId: String) async throws -> Void

    /// Returns a group the current account belongs to, or `nil` when it is gone or not accessible.
    var group: @Sendable (_ groupId: String) async throws -> TeamGroup?

    /// Emits the members of a group, earliest first, again after every join or leave.
    var observeMembers: @Sendable (_ groupId: String) -> AsyncThrowingStream<[TeamMember], Error>

    // MARK: - Invites

    /// Returns the current account's latest invite to a group while it is still open, otherwise a new one.
    var currentInvite: @Sendable (_ group: TeamGroup, _ createdByName: String) async throws -> TeamInvite

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

    /// Emits the group's plan for a day (`nil` while none is published), again after every change.
    var observePlan: @Sendable (_ groupId: String, _ day: String) -> AsyncThrowingStream<TeamPlan?, Error>

    /// Removes the group's plan for a day together with every entry posted to it (owner only, by the rules).
    var deletePlan: @Sendable (_ groupId: String, _ day: String) async throws -> Void

    /// Returns the current account's entry for a day, or `nil` before the first submission.
    var myEntry: @Sendable (_ groupId: String, _ day: String) async throws -> TeamEntry?

    /// Returns the current account's entries for a day across groups, by group id; groups without one are absent.
    var myEntries: @Sendable (_ groupIds: [String], _ day: String) async -> [String: TeamEntry]

    /// Queues the current account's entry for a day (replacing an earlier one); returns without waiting
    /// for the network, so the write survives going offline and the screen closing.
    var submitEntry: @Sendable (_ groupId: String, _ day: String, _ entry: TeamEntry, _ isFirst: Bool) async throws -> Void

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
            myGroups: { try await service.myGroups() },
            createGroup: { try await service.createGroup(name: $0, displayName: $1) },
            leaveGroup: { try await service.leaveGroup(groupId: $0, successorUid: $1) },
            renameGroup: { try await service.renameGroup(groupId: $0, name: $1) },
            transferOwnership: { try await service.transferOwnership(groupId: $0, to: $1) },
            removeMember: { try await service.removeMember(groupId: $0, uid: $1) },
            deleteGroup: { try await service.deleteGroup(groupId: $0) },
            group: { try await service.group(groupId: $0) },
            observeMembers: { service.observeMembers(groupId: $0) },
            currentInvite: { try await service.currentInvite(group: $0, createdByName: $1) },
            createInvite: { try await service.createInvite(group: $0, createdByName: $1) },
            revokeInvite: { try await service.revokeInvite(groupId: $0, inviteId: $1) },
            receiveInvite: { try await service.receiveInvite(reference: $0, displayName: $1) },
            respondToInvite: { try await service.respondToInvite($0, accept: $1) },
            observeMyInvitations: { service.observeMyInvitations() },
            observeSentInvitations: { service.observeSentInvitations(groupId: $0, inviteId: $1) },
            publishPlan: { try await service.publishPlan(groupId: $0, plan: $1) },
            plan: { try await service.plan(groupId: $0, day: $1) },
            observePlan: { service.observePlan(groupId: $0, day: $1) },
            deletePlan: { try await service.deletePlan(groupId: $0, day: $1) },
            myEntry: { try await service.myEntry(groupId: $0, day: $1) },
            myEntries: { await service.myEntries(groupIds: $0, day: $1) },
            submitEntry: { service.submitEntry(groupId: $0, day: $1, entry: $2, isFirst: $3) },
            observeDayEntries: { service.observeDayEntries(groupId: $0, day: $1) },
            weekEntries: { try await service.weekEntries(groupId: $0, days: $1) }
        )
    }()

    static var testValue: TeamClient {
        TeamClient(
            ensureSignedIn: unimplemented("TeamClient.ensureSignedIn"),
            observeMyGroups: unimplemented("TeamClient.observeMyGroups", placeholder: .finished),
            myGroups: unimplemented("TeamClient.myGroups"),
            createGroup: unimplemented("TeamClient.createGroup"),
            leaveGroup: unimplemented("TeamClient.leaveGroup"),
            renameGroup: unimplemented("TeamClient.renameGroup"),
            transferOwnership: unimplemented("TeamClient.transferOwnership"),
            removeMember: unimplemented("TeamClient.removeMember"),
            deleteGroup: unimplemented("TeamClient.deleteGroup"),
            group: unimplemented("TeamClient.group"),
            observeMembers: unimplemented("TeamClient.observeMembers", placeholder: .finished),
            currentInvite: unimplemented("TeamClient.currentInvite"),
            createInvite: unimplemented("TeamClient.createInvite"),
            revokeInvite: unimplemented("TeamClient.revokeInvite"),
            receiveInvite: unimplemented("TeamClient.receiveInvite"),
            respondToInvite: unimplemented("TeamClient.respondToInvite"),
            observeMyInvitations: unimplemented("TeamClient.observeMyInvitations", placeholder: .finished),
            observeSentInvitations: unimplemented("TeamClient.observeSentInvitations", placeholder: .finished),
            publishPlan: unimplemented("TeamClient.publishPlan"),
            plan: unimplemented("TeamClient.plan"),
            observePlan: unimplemented("TeamClient.observePlan", placeholder: .finished),
            deletePlan: unimplemented("TeamClient.deletePlan"),
            myEntry: unimplemented("TeamClient.myEntry"),
            myEntries: unimplemented("TeamClient.myEntries", placeholder: [:]),
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
            myGroups: { [] },
            createGroup: { name, _ in TeamGroup(id: "preview-group", name: name, ownerUid: "preview-uid", createdAt: .now) },
            leaveGroup: { _, _ in },
            renameGroup: { _, _ in },
            transferOwnership: { _, _ in },
            removeMember: { _, _ in },
            deleteGroup: { _ in },
            group: { id in TeamGroup(id: id, name: "Poranna ekipa", ownerUid: "preview-uid", createdAt: .now) },
            observeMembers: { _ in .finished },
            currentInvite: { group, name in
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
            observePlan: { _, _ in .finished },
            deletePlan: { _, _ in },
            myEntry: { _, _ in nil },
            myEntries: { _, _ in [:] },
            submitEntry: { _, _, _, _ in },
            observeDayEntries: { _, _ in .finished },
            weekEntries: { _, _ in [:] }
        )
    }
}

// MARK: - Helpers

private extension AsyncThrowingStream where Failure == Error {
    /// A stream that ends immediately without values.
    nonisolated static var finished: Self {
        Self { $0.finish() }
    }
}
