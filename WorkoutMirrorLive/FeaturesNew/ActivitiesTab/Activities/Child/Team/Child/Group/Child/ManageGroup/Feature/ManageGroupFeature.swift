//
//  ManageGroupFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 30/10/2026.
//

import ComposableArchitecture
import Foundation
import OSLog
import SharedModels

@Reducer
struct ManageGroupFeature {

    @Dependency(\.dismiss) var dismiss
    @Dependency(\.teamClient) var teamClient

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {

            // MARK: - View

            case .view(.viewDidAppear), .view(.retryTapped):
                state.viewState = .loading
                return listenToMembers(groupId: state.group.id)

            case .view(.editTapped):
                state.name = state.group.name
                state.isEditingName = true
                return .none

            case .view(.saveNameTapped):
                guard state.canSaveName else {
                    state.name = state.group.name
                    state.isEditingName = false
                    return .none
                }
                state.alert = .rename
                return .none

            case let .view(.transferTapped(member)):
                guard member.uid != state.myUid, !state.isWorking else { return .none }
                state.alert = .transfer(to: member)
                return .none

            case let .view(.removeTapped(member)):
                guard member.uid != state.myUid, !state.isWorking else { return .none }
                state.alert = .remove(member)
                return .none

            case .view(.deleteGroupTapped):
                guard !state.isWorking else { return .none }
                state.alert = .deleteGroup
                return .none

            // MARK: - Alert

            case .alert(.presented(.confirmRename)):
                let groupId = state.group.id
                let name = state.trimmedName
                return perform(&state, .rename) { [teamClient] in
                    try await teamClient.renameGroup(groupId, name)
                    return .renamed(name)
                }

            case let .alert(.presented(.confirmTransfer(member))):
                let groupId = state.group.id
                return perform(&state, .transfer(member.uid)) { [teamClient] in
                    try await teamClient.transferOwnership(groupId, member.uid)
                    return .ownershipTransferred(member.uid)
                }

            case let .alert(.presented(.confirmRemove(member))):
                let groupId = state.group.id
                return perform(&state, .remove(member.uid)) { [teamClient] in
                    try await teamClient.removeMember(groupId, member.uid)
                    return .memberRemoved(member.uid)
                }

            case .alert(.presented(.confirmDelete)):
                let groupId = state.group.id
                return perform(&state, .delete) { [teamClient] in
                    try await teamClient.deleteGroup(groupId)
                    return .groupDeleted
                }

            // MARK: - Internal

            case let .membersLoaded(members):
                state.members = members
                state.viewState = .success
                return .none

            case .membersFailed:
                state.viewState = .failed
                return .none

            case let .renamed(name):
                state.working = nil
                state.group = Self.group(state.group, name: name)
                state.name = name
                state.isEditingName = false
                return .send(.delegate(.groupChanged(state.group)))

            // The screen is the owner's; after handing the group over it closes.
            case let .ownershipTransferred(uid):
                state.working = nil
                state.group = Self.group(state.group, ownerUid: uid)
                return .run { [group = state.group, dismiss] send in
                    await send(.delegate(.groupChanged(group)))
                    await dismiss()
                }

            case .memberRemoved:
                // The member listener delivers the shorter list.
                state.working = nil
                return .none

            case .groupDeleted:
                state.working = nil
                return .run { [dismiss] send in
                    await send(.delegate(.deleted))
                    await dismiss()
                }

            case let .actionFailed(message):
                state.working = nil
                state.alert = .actionFailed(message)
                return .none

            case .alert, .binding, .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }

    // MARK: - Effects

    // Every confirmed change runs the same way: spinner on, one call, success action or the error alert.
    private func perform(
        _ state: inout State,
        _ working: State.Working,
        _ work: @escaping @Sendable () async throws -> Action
    ) -> Effect<Action> {
        state.working = working
        return .run { send in
            await send(try await work())
        } catch: { error, send in
            Logger.team.error("Manage group failed: \(error.localizedDescription)")
            await send(.actionFailed(error.localizedDescription))
        }
    }

    private func listenToMembers(groupId: String) -> Effect<Action> {
        .run { [teamClient] send in
            for try await members in teamClient.observeMembers(groupId) {
                await send(.membersLoaded(members))
            }
        } catch: { error, send in
            Logger.team.error("Manage group members failed: \(error.localizedDescription)")
            await send(.membersFailed)
        }
        .cancellable(id: ManageGroupCancelID.members, cancelInFlight: true)
    }

    // MARK: - Helpers

    private static func group(_ group: TeamGroup, name: String? = nil, ownerUid: String? = nil) -> TeamGroup {
        TeamGroup(
            id: group.id,
            name: name ?? group.name,
            ownerUid: ownerUid ?? group.ownerUid,
            createdAt: group.createdAt,
            memberCount: group.memberCount,
            lastPlan: group.lastPlan
        )
    }
}
