//
//  InvitationPreviewFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import Foundation
import OSLog
import SharedModels

@Reducer
struct InvitationPreviewFeature {

    @Dependency(\.date) var date
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.teamClient) var teamClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            // MARK: - View

            case let .view(.codeScanned(code)):
                guard state.phase == .scanning else { return .none }
                guard let reference = TeamInviteCode.decode(code) else {
                    state.phase = .failure(.notAnInvite)
                    return .none
                }
                state.phase = .loading
                return .run { [displayName = state.displayName, teamClient, date] send in
                    let invitation = try await teamClient.receiveInvite(reference, displayName)
                    await send(.received(invitation, now: date.now))
                } catch: { error, send in
                    Logger.team.error("Receive invite failed: \(error.localizedDescription)")
                    await send(.failed(Self.failure(for: error)))
                }

            case .view(.joinTapped):
                return respond(&state, accept: true)

            case .view(.declineTapped):
                return respond(&state, accept: false)

            case .view(.laterTapped), .view(.closeTapped):
                return .run { [dismiss] _ in await dismiss() }

            case .view(.scanAgainTapped):
                state.phase = .scanning
                return .none

            // MARK: - Internal

            case let .received(invitation, now):
                state.phase = .preview(invitation, invitation.state(at: now))
                return .none

            case let .failed(failure):
                state.isResponding = false
                state.phase = .failure(failure)
                return .none

            case .responded:
                state.isResponding = false
                return .run { [dismiss] _ in await dismiss() }

            case .delegate:
                return .none
            }
        }
    }

    private func respond(_ state: inout State, accept: Bool) -> Effect<Action> {
        guard case let .preview(invitation, _) = state.phase, !state.isResponding else { return .none }
        state.isResponding = true
        return .run { [teamClient] send in
            try await teamClient.respondToInvite(invitation, accept)
            if accept {
                await send(.delegate(.joined))
            }
            await send(.responded)
        } catch: { error, send in
            Logger.team.error("Respond to invite failed: \(error.localizedDescription)")
            await send(.failed(Self.failure(for: error)))
        }
    }

    nonisolated private static func failure(for error: any Error) -> InvitationPreviewFailure {
        switch error as? TeamServiceError {
        case .inviteNotFound: .notFound
        case .inviteClosed: .closed
        default: .unavailable
        }
    }
}
