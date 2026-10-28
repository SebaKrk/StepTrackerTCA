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

            // MARK: - Destination

            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }

    // Signs in, then keeps the group list live for as long as the tab exists.
    private func startListening() -> Effect<Action> {
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
