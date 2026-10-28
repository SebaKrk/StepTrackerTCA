//
//  TeamService.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 24/10/2026.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation
import OSLog
import SharedModels

/// Firestore implementation behind `TeamClient` — the only place in the app that talks to Firebase for Team.
///
/// Paths: `groups/{g}` · `members/{uid}` · `invites/{i}` · `recipients/{uid}` · `plans/{day}` · `entries/{uid}`.
nonisolated final class TeamService: @unchecked Sendable {

    private static let inviteLifetime: TimeInterval = 7 * 24 * 60 * 60

    // Resolved on each use: Firebase is configured in `AppDelegate`, after this service may be created.
    private var db: Firestore { Firestore.firestore() }

    // MARK: - Account

    func ensureSignedIn() async throws -> String {
        if let uid = Auth.auth().currentUser?.uid {
            return uid
        }
        return try await Auth.auth().signInAnonymously().user.uid
    }

    // MARK: - Groups

    func observeMyGroups() -> AsyncThrowingStream<[TeamGroup], Error> {
        listen(
            query: { [self] uid in db.collectionGroup("members").whereField("uid", isEqualTo: uid) },
            parse: { document in document.reference.parent.parent?.documentID },
            resolve: { [self] groupIds in try await groups(ids: groupIds.compactMap { $0 }) }
        )
    }

    func createGroup(name: String, displayName: String) async throws -> TeamGroup {
        let uid = try await ensureSignedIn()
        let now = Date()
        let groupRef = db.collection("groups").document()
        let batch = db.batch()
        batch.setData(TeamDocumentMapper.groupData(name: name, ownerUid: uid, createdAt: now), forDocument: groupRef)
        batch.setData(
            TeamDocumentMapper.memberData(uid: uid, displayName: displayName, joinedAt: now, joinedViaInvite: nil),
            forDocument: groupRef.collection("members").document(uid)
        )
        try await batch.commit()
        return TeamGroup(id: groupRef.documentID, name: name, ownerUid: uid, createdAt: now)
    }

    func leaveGroup(groupId: String) async throws {
        let uid = try await ensureSignedIn()
        try await groupRef(groupId).collection("members").document(uid).delete()
    }

    func group(groupId: String) async throws -> TeamGroup? {
        let ref = groupRef(groupId)
        guard let data = try await ref.getDocument().data() else { return nil }
        return try TeamDocumentMapper.group(id: groupId, data: data, path: ref.path)
    }

    func observeMembers(groupId: String) -> AsyncThrowingStream<[TeamMember], Error> {
        listen(
            query: { [self] _ in groupRef(groupId).collection("members").order(by: "joinedAt") },
            parse: { document in try TeamDocumentMapper.member(data: document.data(), path: document.reference.path) },
            resolve: { members in members }
        )
    }

    // MARK: - Invites

    // Reopening the invite screen shows the same code (and its scans) until it expires or is revoked.
    func currentInvite(group: TeamGroup, createdByName: String) async throws -> TeamInvite {
        let uid = try await ensureSignedIn()
        let latest = try await groupRef(group.id).collection("invites")
            .whereField("createdByUid", isEqualTo: uid)
            .order(by: "createdAt", descending: true)
            .limit(to: 1)
            .getDocuments()
            .documents
            .first
        if let latest {
            let invite = try TeamDocumentMapper.invite(
                id: latest.documentID,
                groupId: group.id,
                data: latest.data(),
                path: latest.reference.path
            )
            if invite.isOpen(at: Date()) {
                return invite
            }
        }
        return try await createInvite(group: group, createdByName: createdByName)
    }

    func createInvite(group: TeamGroup, createdByName: String) async throws -> TeamInvite {
        let uid = try await ensureSignedIn()
        let now = Date()
        let inviteRef = groupRef(group.id).collection("invites").document()
        let invite = TeamInvite(
            id: inviteRef.documentID,
            groupId: group.id,
            groupName: group.name,
            createdByUid: uid,
            createdByName: createdByName,
            createdAt: now,
            expiresAt: now.addingTimeInterval(Self.inviteLifetime),
            isRevoked: false
        )
        try await inviteRef.setData(TeamDocumentMapper.inviteData(invite))
        return invite
    }

    func revokeInvite(groupId: String, inviteId: String) async throws {
        try await inviteRef(groupId, inviteId).updateData(["revoked": true])
    }

    func receiveInvite(reference: TeamInviteReference, displayName: String) async throws -> TeamInvitation {
        let uid = try await ensureSignedIn()
        let invite = try await fetchInvite(reference)
        let recipientRef = inviteRef(reference.groupId, reference.inviteId).collection("recipients").document(uid)
        let snapshot = try await recipientRef.getDocument()

        if let data = snapshot.data() {
            let existing = try TeamDocumentMapper.recipient(reference: reference, data: data, path: recipientRef.path)
                .invitation(with: invite)
            guard existing.status == .declined else { return existing }
        }
        guard invite.isOpen(at: Date()) else { throw TeamServiceError.inviteClosed }

        let now = Date()
        try await recipientRef.setData(
            TeamDocumentMapper.recipientData(uid: uid, displayName: displayName, status: .pending, scannedAt: now)
        )
        return TeamInvitation(
            invite: invite,
            recipientUid: uid,
            recipientName: displayName,
            status: .pending,
            scannedAt: now,
            respondedAt: nil
        )
    }

    func respondToInvite(_ invitation: TeamInvitation, accept: Bool) async throws {
        let uid = try await ensureSignedIn()
        let invite = invitation.invite
        let recipientRef = inviteRef(invite.groupId, invite.id).collection("recipients").document(uid)
        let now = Date()
        let decision: [String: Any] = [
            "status": (accept ? TeamRecipientStatus.accepted : .declined).rawValue,
            "respondedAt": Timestamp(date: now),
        ]
        guard accept else {
            try await recipientRef.updateData(decision)
            return
        }
        // The member rule checks the accepted status after the whole batch, so both writes land or neither.
        let batch = db.batch()
        batch.updateData(decision, forDocument: recipientRef)
        batch.setData(
            TeamDocumentMapper.memberData(
                uid: uid,
                displayName: invitation.recipientName,
                joinedAt: now,
                joinedViaInvite: invite.id
            ),
            forDocument: groupRef(invite.groupId).collection("members").document(uid)
        )
        try await batch.commit()
    }

    func observeMyInvitations() -> AsyncThrowingStream<[TeamInvitation], Error> {
        listen(
            query: { [self] uid in
                db.collectionGroup("recipients")
                    .whereField("uid", isEqualTo: uid)
                    .order(by: "scannedAt", descending: true)
            },
            parse: { document in
                let inviteRef = document.reference.parent.parent
                let reference: TeamInviteReference? =
                    if let inviteId = inviteRef?.documentID, let groupId = inviteRef?.parent.parent?.documentID {
                        TeamInviteReference(groupId: groupId, inviteId: inviteId)
                    } else {
                        nil
                    }
                return try TeamDocumentMapper.recipient(reference: reference, data: document.data(), path: document.reference.path)
            },
            resolve: { [self] recipients in try await invitations(from: recipients) }
        )
    }

    func observeSentInvitations(groupId: String, inviteId: String) -> AsyncThrowingStream<[TeamInvitation], Error> {
        listen(
            query: { [self] _ in
                inviteRef(groupId, inviteId).collection("recipients").order(by: "scannedAt", descending: true)
            },
            parse: { document in
                try TeamDocumentMapper.recipient(
                    reference: TeamInviteReference(groupId: groupId, inviteId: inviteId),
                    data: document.data(),
                    path: document.reference.path
                )
            },
            resolve: { [self] recipients in try await invitations(from: recipients) }
        )
    }

    // MARK: - Plans and entries

    func publishPlan(groupId: String, plan: TeamPlan) async throws {
        try await groupRef(groupId).collection("plans").document(plan.id).setData(TeamDocumentMapper.planData(plan))
    }

    func plan(groupId: String, day: String) async throws -> TeamPlan? {
        let planRef = groupRef(groupId).collection("plans").document(day)
        guard let data = try await planRef.getDocument().data() else { return nil }
        return try TeamDocumentMapper.plan(id: day, data: data, path: planRef.path)
    }

    func observePlan(groupId: String, day: String) -> AsyncThrowingStream<TeamPlan?, Error> {
        let planRef = groupRef(groupId).collection("plans").document(day)
        return AsyncThrowingStream { continuation in
            let handle = TeamListenerHandle()
            let listener = planRef.addSnapshotListener { snapshot, error in
                if let error {
                    continuation.finish(throwing: error)
                    return
                }
                guard let snapshot else { return }
                do {
                    let plan = try snapshot.data().map { try TeamDocumentMapper.plan(id: day, data: $0, path: planRef.path) }
                    continuation.yield(plan)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            handle.attach(listener)
            continuation.onTermination = { _ in handle.remove() }
        }
    }

    func myEntry(groupId: String, day: String) async throws -> TeamEntry? {
        let uid = try await ensureSignedIn()
        let ref = groupRef(groupId).collection("plans").document(day).collection("entries").document(uid)
        guard let data = try await ref.getDocument().data() else { return nil }
        return try TeamDocumentMapper.entry(data: data, path: ref.path)
    }

    // Not awaited: Firestore keeps the write in its local queue and sends it when online,
    // even after the Summary screen that triggered it has closed.
    func submitEntry(groupId: String, day: String, entry: TeamEntry) {
        let path = "groups/\(groupId)/plans/\(day)/entries/\(entry.uid)"
        groupRef(groupId)
            .collection("plans").document(day)
            .collection("entries").document(entry.uid)
            .setData(TeamDocumentMapper.entryData(entry)) { error in
                if let error {
                    Logger.team.error("Entry \(path) not saved: \(error.localizedDescription)")
                }
            }
    }

    func observeDayEntries(groupId: String, day: String) -> AsyncThrowingStream<[TeamEntry], Error> {
        listen(
            query: { [self] _ in groupRef(groupId).collection("plans").document(day).collection("entries") },
            parse: { document in try TeamDocumentMapper.entry(data: document.data(), path: document.reference.path) },
            resolve: { entries in entries }
        )
    }

    func weekEntries(groupId: String, days: [String]) async throws -> [String: [TeamEntry]] {
        try await withThrowingTaskGroup(of: (String, [TeamEntry])?.self) { group in
            for day in days {
                group.addTask { [self] in
                    let planRef = groupRef(groupId).collection("plans").document(day)
                    guard try await planRef.getDocument().exists else { return nil }
                    let entries = try await planRef.collection("entries").getDocuments().documents
                        .map { try TeamDocumentMapper.entry(data: $0.data(), path: $0.reference.path) }
                    return (day, entries)
                }
            }
            var entriesByDay: [String: [TeamEntry]] = [:]
            for try await result in group {
                if let (day, entries) = result {
                    entriesByDay[day] = entries
                }
            }
            return entriesByDay
        }
    }

    // MARK: - Listening

    /// Turns a Firestore query into a stream. `parse` runs on the snapshot (it must not keep Firestore objects);
    /// `resolve` may fetch more and runs per snapshot, with stale results dropped.
    private func listen<Item: Sendable, Value: Sendable>(
        query: @escaping @Sendable (_ uid: String) -> Query,
        parse: @escaping @Sendable (QueryDocumentSnapshot) throws -> Item,
        resolve: @escaping @Sendable ([Item]) async throws -> Value
    ) -> AsyncThrowingStream<Value, Error> {
        AsyncThrowingStream { continuation in
            let handle = TeamListenerHandle()
            let task = Task { [self] in
                do {
                    let uid = try await ensureSignedIn()
                    // Metadata changes re-resolve once the server confirms a local write; reads made before that can be denied by the rules.
                    let listener = query(uid).addSnapshotListener(includeMetadataChanges: true) { snapshot, error in
                        if let error {
                            continuation.finish(throwing: error)
                            return
                        }
                        guard let snapshot else { return }
                        do {
                            let items = try snapshot.documents.map(parse)
                            let generation = handle.nextGeneration()
                            Task {
                                do {
                                    let value = try await resolve(items)
                                    if handle.isLatest(generation) {
                                        continuation.yield(value)
                                    }
                                } catch {
                                    continuation.finish(throwing: error)
                                }
                            }
                        } catch {
                            continuation.finish(throwing: error)
                        }
                    }
                    handle.attach(listener)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
                handle.remove()
            }
        }
    }

    // MARK: - Lookups

    private func groupRef(_ groupId: String) -> DocumentReference {
        db.collection("groups").document(groupId)
    }

    private func inviteRef(_ groupId: String, _ inviteId: String) -> DocumentReference {
        groupRef(groupId).collection("invites").document(inviteId)
    }

    private func fetchInvite(_ reference: TeamInviteReference) async throws -> TeamInvite {
        let ref = inviteRef(reference.groupId, reference.inviteId)
        guard let data = try await ref.getDocument().data() else { throw TeamServiceError.inviteNotFound }
        return try TeamDocumentMapper.invite(id: reference.inviteId, groupId: reference.groupId, data: data, path: ref.path)
    }

    // A group the account has just left can still be in a stale snapshot — skip it instead of failing the list.
    private func groups(ids: [String]) async throws -> [TeamGroup] {
        try await withThrowingTaskGroup(of: TeamGroup?.self) { group in
            for id in Set(ids) {
                group.addTask { [self] in
                    let ref = groupRef(id)
                    guard let data = try? await ref.getDocument().data() else { return nil }
                    return try TeamDocumentMapper.group(id: id, data: data, path: ref.path)
                }
            }
            var groups: [TeamGroup] = []
            for try await result in group {
                if let result { groups.append(result) }
            }
            return groups.sorted { $0.createdAt < $1.createdAt }
        }
    }

    // Invites are fetched once per distinct invite, however many recipients share it.
    private func invitations(from recipients: [TeamRecipientRecord]) async throws -> [TeamInvitation] {
        let references = Set(recipients.compactMap(\.reference))
        let invites = try await withThrowingTaskGroup(of: TeamInvite?.self) { group in
            for reference in references {
                group.addTask { [self] in try? await fetchInvite(reference) }
            }
            var invitesById: [String: TeamInvite] = [:]
            for try await result in group {
                if let result { invitesById[result.id] = result }
            }
            return invitesById
        }
        return recipients.compactMap { recipient in
            recipient.reference
                .flatMap { invites[$0.inviteId] }
                .map { recipient.invitation(with: $0) }
        }
    }
}
