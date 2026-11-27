//
//  PlanRefinement.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 27/11/2026.
//

import Foundation
import SharedModels

/// The model's answer in the plan chat: what it says, and a corrected board once the athlete confirmed.
public struct PlanRefinement: Sendable, Equatable {

    /// The reply to show in the chat.
    public let reply: String

    /// The corrected board; `nil` while the model still asks or restates.
    public let board: ScannedBoard?

    /// One short line per change the board makes; empty without a board.
    public let changes: [String]

    public init(reply: String, board: ScannedBoard?, changes: [String]) {
        self.reply = reply
        self.board = board
        self.changes = changes
    }
}
