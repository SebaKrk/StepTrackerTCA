//
//  PlanChatFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/11/2026.
//

import ComposableArchitecture
import Foundation
import HealthHub
import SharedModels
import SwiftUI

extension PlanChatFeature {

    /// Messages the user may send in one chat; the server enforces the same number.
    static let maxUserMessages = 6

    /// Longest message the server reads in full.
    static let maxMessageLength = 1_000

    /// Dictation stops on its own after this long, so a forgotten microphone does not stay open.
    static let maxDictationDuration: Duration = .seconds(60)

    /// How long Send waits for the final dictated words before it lets go of the session.
    static let dictationFinishGrace: Duration = .seconds(3)

    @ObservableState
    struct State: Equatable {

        // MARK: - Properties

        /// The color representing the training readiness level; fills the user's bubbles and "Apply".
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .gray

        /// The board as scanned; every turn sends it unchanged, the correction comes back whole.
        let board: ScannedBoard

        /// Doubts the scan review raised, as the user reads them.
        let findings: [String]

        /// The chat so far, oldest first.
        var messages: [PlanChatMessage] = []

        /// What the user is typing.
        var inputText = ""

        /// True once the sheet is open fully; typing keeps it there instead of folding back to half.
        var isExpanded = false

        /// True while the model is answering.
        var isSending = false

        /// The corrected board waiting for "Apply"; `nil` while the model still asks.
        var proposal: PlanRefinement?

        /// Why the last turn failed; shown under the chat.
        var failure: ScanFailure?

        /// Where dictation stands; anything but idle means the microphone owns the field's text.
        var dictationPhase: DictationPhase = .idle

        /// The field's text from before dictation; the transcript is appended to it.
        var textBeforeDictation = ""

        /// True once "Send" was tapped while dictating; the message goes out after the last words arrive.
        var sendsAfterDictation = false

        // MARK: - Derived

        /// Messages the user has sent in this chat.
        var userMessageCount: Int {
            messages.filter { $0.role == .user }.count
        }

        /// True once the chat used up its messages.
        var isMessageLimitReached: Bool {
            userMessageCount >= PlanChatFeature.maxUserMessages
        }

        /// True while the microphone is preparing or listening.
        var isDictating: Bool {
            dictationPhase == .preparing || dictationPhase == .recording
        }

        /// True when the field is empty and idle, so the microphone takes the send button's place.
        var canDictate: Bool {
            dictationPhase == .idle && inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        /// Whether the send button can fire.
        var canSend: Bool {
            !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending && !isMessageLimitReached
        }
    }
}
