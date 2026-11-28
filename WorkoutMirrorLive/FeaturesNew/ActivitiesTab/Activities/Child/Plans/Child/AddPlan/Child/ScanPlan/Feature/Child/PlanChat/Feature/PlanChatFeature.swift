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

    /// Turns speech into text on the device.
    @Dependency(\.dictationClient) var dictationClient

    /// Measures the dictation's time limit.
    @Dependency(\.continuousClock) var clock

    // MARK: - Cancel ID

    private nonisolated enum CancelID: Hashable, Sendable {

        /// The dictation session.
        case dictation

        /// The dictation's time limit, and the grace period for its last words.
        case dictationTimer
    }

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
                // While dictating, "Send" first waits for the last words, then sends them.
                if state.dictationPhase == .preparing {
                    return .merge(stopDictation(&state), sendMessage(&state))
                }
                if state.dictationPhase != .idle {
                    state.sendsAfterDictation = true
                    return finishDictation(&state)
                }
                return sendMessage(&state)

            case let .internal(.replied(refinement)):
                state.isSending = false
                state.messages.append(PlanChatMessage(role: .assistant, text: refinement.reply))
                // A reply that only asks keeps the last proposal: it is still what "Apply" would hand up.
                if let board = refinement.board {
                    state.latestBoard = board
                    // The board carries every turn's edits, so the card lists them all.
                    let earlier = state.proposal?.changes ?? []
                    let added = refinement.changes.filter { !earlier.contains($0) }
                    state.proposal = PlanRefinement(reply: refinement.reply, board: board, changes: earlier + added)
                }
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
                Self.endDictation(&state)
                return .merge(.cancel(id: CancelID.dictation), .cancel(id: CancelID.dictationTimer), .send(.delegate(.closed)))

            case .view(.micTapped):
                // A finishing session still holds the audio session; a new one would lose the microphone.
                guard state.dictationPhase == .idle, !state.isMessageLimitReached else { return .none }
                state.textBeforeDictation = state.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                state.dictationPhase = .preparing
                state.failure = nil
                // A pending grace period from the previous dictation would end this one.
                let previousTimer = Effect<Action>.cancel(id: CancelID.dictationTimer)
                return .concatenate(previousTimer, .run { [dictationClient] send in
                    for try await event in dictationClient.start(Locale.current, []) {
                        await send(.internal(.dictationEvent(event)))
                    }
                    await send(.internal(.dictationFinished))
                } catch: { error, send in
                    await send(.internal(.dictationFailed(Self.dictationFailure(for: error))))
                }
                .cancellable(id: CancelID.dictation, cancelInFlight: true))

            case .internal(.dictationTimedOut):
                return finishDictation(&state)

            case .internal(.dictationFinished):
                guard state.dictationPhase != .idle else { return .none }
                let sends = state.sendsAfterDictation
                Self.endDictation(&state)
                let stop = Effect<Action>.merge(.cancel(id: CancelID.dictation), .cancel(id: CancelID.dictationTimer))
                return sends ? .merge(stop, sendMessage(&state)) : stop

            case .internal(.dictationEvent(.listening)):
                guard state.isDictating else { return .none }
                state.dictationPhase = .recording
                // The limit counts from the open microphone, so a first model download does not eat it.
                return .run { [clock] send in
                    try await clock.sleep(for: PlanChatFeature.maxDictationDuration)
                    await send(.internal(.dictationTimedOut))
                }
                .cancellable(id: CancelID.dictationTimer, cancelInFlight: true)

            case let .internal(.dictationEvent(.transcript(transcript))):
                guard state.dictationPhase != .idle else { return .none }
                if state.isDictating { state.dictationPhase = .recording }
                let separator = state.textBeforeDictation.isEmpty || transcript.isEmpty ? "" : " "
                let joined = state.textBeforeDictation + separator + transcript
                state.inputText = String(joined.prefix(PlanChatFeature.maxMessageLength))
                guard joined.count >= PlanChatFeature.maxMessageLength else { return .none }
                return finishDictation(&state)

            case let .internal(.dictationFailed(failure)):
                // Words already dictated stay in the field; only the session is lost.
                Self.endDictation(&state)
                state.failure = failure
                return .merge(.cancel(id: CancelID.dictation), .cancel(id: CancelID.dictationTimer))

            case .view(.inputFocused):
                // Half a sheet under a keyboard leaves no room for the chat.
                state.isExpanded = true
                // Tapping the field means the user corrects by hand; late words would overwrite the typing.
                return state.dictationPhase == .idle ? .none : stopDictation(&state)

            case let .view(.detentChanged(isExpanded)):
                state.isExpanded = isExpanded
                return .none

            case .delegate:
                return .none
            }
        }
    }

    // MARK: - Sending

    private func sendMessage(_ state: inout State) -> Effect<Action> {
        guard state.canSend else { return .none }
        let text = state.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        state.messages.append(PlanChatMessage(role: .user, text: text))
        state.inputText = ""
        state.isSending = true
        state.failure = nil
        return .run { [board = state.workingBoard, findings = state.findings, messages = state.messages, extractionClient] send in
            do {
                let refinement = try await extractionClient.refinePlan(board, findings, messages)
                await send(.internal(.replied(refinement)))
            } catch {
                await send(.internal(.failed(Self.failure(for: error))))
            }
        }
    }

    // MARK: - Dictation

    // Closing the microphone instead of cancelling lets the model turn its draft into final words.
    private func finishDictation(_ state: inout State) -> Effect<Action> {
        switch state.dictationPhase {
        case .idle, .finishing:
            return .none
        case .preparing:
            // Nothing was heard yet, so there are no words to wait for.
            return stopDictation(&state)
        case .recording:
            state.dictationPhase = .finishing
            return .merge(
                .run { [dictationClient] _ in await dictationClient.finish() },
                .run { [clock] send in
                    try await clock.sleep(for: PlanChatFeature.dictationFinishGrace)
                    await send(.internal(.dictationFinished))
                }
                .cancellable(id: CancelID.dictationTimer, cancelInFlight: true)
            )
        }
    }

    private func stopDictation(_ state: inout State) -> Effect<Action> {
        Self.endDictation(&state)
        return .merge(.cancel(id: CancelID.dictation), .cancel(id: CancelID.dictationTimer))
    }

    private static func endDictation(_ state: inout State) {
        state.dictationPhase = .idle
        state.textBeforeDictation = ""
        state.sendsAfterDictation = false
    }

    nonisolated static func dictationFailure(for error: any Error) -> ScanFailure {
        switch error as? DictationError {
        case .microphoneDenied:
            return ScanFailure(
                title: String(localized: "No microphone access"),
                message: String(localized: "Allow the microphone in Settings to dictate messages."),
                canRetry: false
            )
        case .unsupportedLocale:
            return ScanFailure(
                title: String(localized: "Dictation unavailable"),
                message: String(localized: "Dictation does not support your language on this iPhone yet."),
                canRetry: false
            )
        case .modelUnavailable:
            return ScanFailure(
                title: String(localized: "Dictation unavailable"),
                message: String(localized: "The speech model is still downloading. Try again in a moment."),
                canRetry: false
            )
        case .audioConversionFailed, nil:
            return ScanFailure(
                title: String(localized: "Dictation stopped"),
                message: String(localized: "Something went wrong with the microphone. Try again."),
                canRetry: false
            )
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
