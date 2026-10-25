//
//  TeamFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import Foundation
import OSLog
import SharedModels

@Reducer
struct TeamFeature {

    @Dependency(\.date) var date
    @Dependency(\.teamClient) var teamClient
    @Dependency(\.userProfileClient) var userProfileClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            // MARK: - View

            case .view(.viewDidAppear):
                guard !state.hasStarted else { return .none }
                state.hasStarted = true
                return startListening()

            case let .view(.segmentChanged(segment)):
                state.segment = segment
                return .none

            case .view(.retryTapped):
                state.viewState = .loading
                return startListening()

            case .view(.createGroupTapped):
                state.destination = .createGroup(CreateGroupFeature.State(displayName: state.displayName))
                return .none

            case let .view(.invitationJoinTapped(invitation)):
                return respond(&state, to: invitation, accept: true)

            case let .view(.invitationDeclineTapped(invitation)):
                return respond(&state, to: invitation, accept: false)

            case .view(.scanInviteTapped):
                state.destination = .invitationPreview(
                    InvitationPreviewFeature.State(displayName: state.displayName)
                )
                return .none

            case let .view(.groupTapped(group)):
                guard let myUid = state.myUid else { return .none }
                state.destination = .group(
                    GroupFeature.State(group: group, myUid: myUid, displayName: state.displayName)
                )
                return .none

            // MARK: - Internal

            case let .signedIn(uid, displayName):
                state.myUid = uid
                state.displayName = displayName
                return .none

            case let .groupsUpdated(groups):
                state.groups = groups
                state.viewState = .success
                return .none

            case .groupsFailed:
                state.viewState = .failed
                return .none

            case let .invitationsUpdated(invitations, now):
                state.pendingInvitations = invitations.filter { $0.state(at: now) == .pending }
                return .none

            case let .invitationResponseFinished(id):
                state.respondingInvitationIds.remove(id)
                return .none

            // MARK: - Destination

            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }

    // Groups and scanned invites stay live for as long as the tab exists.
    private func startListening() -> Effect<Action> {
        .merge(listenToGroups(), listenToInvitations())
    }

    private func listenToInvitations() -> Effect<Action> {
        .run { [teamClient, date] send in
            for try await invitations in teamClient.observeMyInvitations() {
                await send(.invitationsUpdated(invitations, now: date.now))
            }
        } catch: { error, _ in
            Logger.team.error("Team invitations failed: \(error.localizedDescription)")
        }
        .cancellable(id: TeamCancelID.invitations, cancelInFlight: true)
    }

    // The listeners update both lists; this only tracks the spinner.
    private func respond(_ state: inout State, to invitation: TeamInvitation, accept: Bool) -> Effect<Action> {
        guard !state.respondingInvitationIds.contains(invitation.id) else { return .none }
        state.respondingInvitationIds.insert(invitation.id)
        return .run { [teamClient] send in
            try await teamClient.respondToInvite(invitation, accept)
            await send(.invitationResponseFinished(invitation.id))
        } catch: { error, send in
            Logger.team.error("Respond to invite failed: \(error.localizedDescription)")
            await send(.invitationResponseFinished(invitation.id))
        }
    }

    // Signs in, then keeps the group list live.
    private func listenToGroups() -> Effect<Action> {
        .run { [teamClient, userProfileClient] send in
            let uid = try await teamClient.ensureSignedIn()
            let profile = try? await userProfileClient.fetch()
            await send(.signedIn(uid: uid, displayName: Self.displayName(profile: profile, uid: uid)))
            for try await groups in teamClient.observeMyGroups() {
                await send(.groupsUpdated(groups))
            }
        } catch: { error, send in
            Logger.team.error("Team groups failed: \(error.localizedDescription)")
            await send(.groupsFailed)
        }
        .cancellable(id: TeamCancelID.groups, cancelInFlight: true)
    }

    // Same order as GymRoom: nickname, then first name, then a stable "Athlete-XXX".
    nonisolated private static func displayName(profile: UserProfile?, uid: String) -> String {
        if let nickname = profile?.nickname, !nickname.isEmpty {
            return nickname
        }
        if let name = profile?.name, !name.isEmpty {
            return name
        }
        return "Athlete-" + uid.prefix(3).uppercased()
    }
}
