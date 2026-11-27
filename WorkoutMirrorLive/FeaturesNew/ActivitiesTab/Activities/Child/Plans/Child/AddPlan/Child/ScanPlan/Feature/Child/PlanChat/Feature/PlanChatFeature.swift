//
//  PlanChatFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/11/2026.
//

import ComposableArchitecture
import Foundation
import HealthHub
import SharedModels
import SwiftUI

/// Chat that corrects a scanned plan: the model restates the change, the user confirms, "Apply" hands the board up.
@Reducer
struct PlanChatFeature {

    // MARK: - Dependency

    @Dependency(\.workoutExtractionClient) var extractionClient

    // MARK: - Body

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
            switch action {

            case .binding(\.inputText):
                // The server cuts longer messages silently, so the field stops where the server would.
                if state.inputText.count > PlanChatFeature.maxMessageLength {
                    state.inputText = String(state.inputText.prefix(PlanChatFeature.maxMessageLength))
                }
                return .none

            case .binding:
                return .none

            case .view(.sendTapped):
                guard state.canSend else { return .none }
                let text = state.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                state.messages.append(PlanChatMessage(role: .user, text: text))
                state.inputText = ""
                state.isSending = true
                state.failure = nil
                // A new message reopens the question, so an older proposal no longer stands.
                state.proposal = nil
                return .run { [board = state.board, findings = state.findings, messages = state.messages, extractionClient] send in
                    do {
                        let refinement = try await extractionClient.refinePlan(board, findings, messages)
                        await send(.internal(.replied(refinement)))
                    } catch {
                        await send(.internal(.failed(Self.failure(for: error))))
                    }
                }

            case let .internal(.replied(refinement)):
                state.isSending = false
                state.messages.append(PlanChatMessage(role: .assistant, text: refinement.reply))
                state.proposal = refinement.board == nil ? nil : refinement
                return .none

            case let .internal(.failed(failure)):
                state.isSending = false
                state.failure = failure
                // An unanswered message goes back to the field, so a retry costs no extra turn of the six.
                if state.messages.last?.role == .user, let unanswered = state.messages.popLast(), state.inputText.isEmpty {
                    state.inputText = unanswered.text
                }
                return .none

            case .view(.applyTapped):
                guard let board = state.proposal?.board else { return .none }
                return .send(.delegate(.applied(board)))

            case .view(.closeTapped):
                return .send(.delegate(.closed))

            case .view(.inputFocused):
                // Half a sheet under a keyboard leaves no room for the chat.
                state.isExpanded = true
                return .none

            case let .view(.detentChanged(isExpanded)):
                state.isExpanded = isExpanded
                return .none

            case .delegate:
                return .none
            }
        }
    }

    // MARK: - Failures

    /// The scan's daily-limit copy talks about scans, so the chat speaks about corrections instead.
    nonisolated static func failure(for error: any Error) -> ScanFailure {
        if case .dailyLimitReached = error as? ScanProxyError {
            return ScanFailure(
                title: String(localized: "Daily limit reached"),
                message: String(localized: "You have used today's AI corrections. Correct the plan in the editor or try tomorrow."),
                canRetry: false
            )
        }
        return ScanProxyError.scanFailure(for: error)
    }
}
