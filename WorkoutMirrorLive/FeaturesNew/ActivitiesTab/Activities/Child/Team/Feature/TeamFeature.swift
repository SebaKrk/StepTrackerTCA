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

    @Dependency(\.calendar) var calendar
    @Dependency(\.date) var date
    @Dependency(\.teamClient) var teamClient
    @Dependency(\.userProfileClient) var userProfileClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            // MARK: - View

            case .view(.viewDidAppear):
                guard !state.hasStarted else { return refreshGroups() }
                state.hasStarted = true
                return startListening()

            case .view(.refreshPulled):
                return refreshGroups()

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
                state.alert = Self.declineConfirmation(invitation)
                return .none

            case let .alert(.presented(.confirmDecline(invitation))):
                return respond(&state, to: invitation, accept: false)

            case .view(.scanInviteTapped):
                state.destination = .invitationPreview(
                    InvitationPreviewFeature.State(displayName: state.displayName, color: state.color)
                )
                return .none

            case let .view(.groupTapped(group)):
                guard let myUid = state.myUid else { return .none }
                state.destination = .group(
                    GroupFeature.State(group: group, myUid: myUid, displayName: state.displayName, color: state.color)
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
                state.today = TeamDay.id(for: date.now, calendar: calendar)
                return loadMyEntries(groups: groups, today: state.today)

            case let .myEntriesLoaded(entries):
                state.myEntries = entries
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

            case .alert, .destination:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$destination, action: \.destination)
    }

    // Only groups with a plan today have a result to show.
    private func loadMyEntries(groups: [TeamGroup], today: String) -> Effect<Action> {
        let groupIds = groups.filter { $0.lastPlan?.day == today }.map(\.id)
        guard !groupIds.isEmpty else { return .send(.myEntriesLoaded([:])) }
        return .run { [teamClient] send in
            await send(.myEntriesLoaded(await teamClient.myEntries(groupIds, today)))
        }
        .cancellable(id: TeamCancelID.myEntries, cancelInFlight: true)
    }

    private static func declineConfirmation(_ invitation: TeamInvitation) -> AlertState<Action.Alert> {
        AlertState {
            TextState(String(localized: "Decline Invitation?"))
        } actions: {
            ButtonState(role: .destructive, action: .confirmDecline(invitation)) {
                TextState(String(localized: "Decline"))
            }
            ButtonState(role: .cancel) {
                TextState(String(localized: "Cancel"))
            }
        } message: {
            TextState(String(localized: "You can join \(invitation.invite.groupName) later only by scanning the code again."))
        }
    }

    // Counters on the group documents change outside the membership listener, so a visit re-reads them.
    private func refreshGroups() -> Effect<Action> {
        .run { [teamClient] send in
            await send(.groupsUpdated(try await teamClient.myGroups()))
        } catch: { error, _ in
            Logger.team.error("Team groups refresh failed: \(error.localizedDescription)")
        }
        .cancellable(id: TeamCancelID.refresh, cancelInFlight: true)
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
            let displayName = TeamDisplayName.make(nickname: profile?.nickname, name: profile?.name, uid: uid)
            await send(.signedIn(uid: uid, displayName: displayName))
            for try await groups in teamClient.observeMyGroups() {
                await send(.groupsUpdated(groups))
            }
        } catch: { error, send in
            Logger.team.error("Team groups failed: \(error.localizedDescription)")
            await send(.groupsFailed)
        }
        .cancellable(id: TeamCancelID.groups, cancelInFlight: true)
    }
}
