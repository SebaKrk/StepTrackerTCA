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

        // MARK: - Derived

        /// Messages the user has sent in this chat.
        var userMessageCount: Int {
            messages.filter { $0.role == .user }.count
        }

        /// True once the chat used up its messages.
        var isMessageLimitReached: Bool {
            userMessageCount >= PlanChatFeature.maxUserMessages
        }

        /// Whether the send button can fire.
        var canSend: Bool {
            !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending && !isMessageLimitReached
        }
    }
}
