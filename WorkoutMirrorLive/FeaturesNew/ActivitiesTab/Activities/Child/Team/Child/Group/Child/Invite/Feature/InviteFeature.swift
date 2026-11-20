//
//  InviteFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import Foundation
import OSLog
import SharedModels

@Reducer
struct InviteFeature {

    @Dependency(\.date) var date
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.qrCodeImageClient) var qrCodeImageClient
    @Dependency(\.teamClient) var teamClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            // MARK: - View

            case .view(.viewDidAppear):
                guard state.invite == nil else { return .none }
                return .run { [group = state.group, name = state.displayName, teamClient, qrCodeImageClient] send in
                    let invite = try await teamClient.currentInvite(group, name)
                    await send(.inviteReady(invite, await qrCodeImageClient.image(Self.code(for: invite))))
                } catch: { error, send in
                    Logger.team.error("Invite failed: \(error.localizedDescription)")
                    await send(.failed)
                }

            case .view(.replaceCodeTapped):
                guard let invite = state.invite, !state.isReplacing else { return .none }
                state.isReplacing = true
                return .run { [group = state.group, name = state.displayName, teamClient, qrCodeImageClient] send in
                    try await teamClient.revokeInvite(invite.groupId, invite.id)
                    let replacement = try await teamClient.createInvite(group, name)
                    await send(.inviteReady(replacement, await qrCodeImageClient.image(Self.code(for: replacement))))
                } catch: { error, send in
                    Logger.team.error("Replace invite failed: \(error.localizedDescription)")
                    await send(.failed)
                }

            case .view(.doneTapped):
                return .run { [dismiss] _ in await dismiss() }

            // MARK: - Internal

            case let .inviteReady(invite, image):
                state.invite = invite
                state.qrImage = image
                state.scans = []
                state.isReplacing = false
                state.viewState = .success
                return .run { [teamClient, date] send in
                    for try await invitations in teamClient.observeSentInvitations(invite.groupId, invite.id) {
                        await send(.scansUpdated(invitations, now: date.now))
                    }
                } catch: { error, _ in
                    Logger.team.error("Invite scans failed: \(error.localizedDescription)")
                }
                .cancellable(id: InviteCancelID.scans, cancelInFlight: true)

            case let .scansUpdated(invitations, now):
                state.scans = invitations.map { InviteScanRow(invitation: $0, state: $0.state(at: now)) }
                return .none

            case .failed:
                state.isReplacing = false
                state.viewState = .failed
                return .none
            }
        }
    }

    nonisolated private static func code(for invite: TeamInvite) -> String {
        TeamInviteCode.encode(groupId: invite.groupId, inviteId: invite.id)
    }
}
