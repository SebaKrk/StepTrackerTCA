//
//  TeamLeaderboardRow.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 24/10/2026.
//

import Foundation

/// One line of a day leaderboard.
public struct TeamLeaderboardRow: Identifiable, Equatable, Sendable {

    /// Place from 1; `nil` when the entry cannot be ranked under the current lens.
    public let place: Int?

    /// The member's entry.
    public let entry: TeamEntry

    /// The entry belongs to the current user.
    public let isMe: Bool

    public var id: String { entry.uid }

    public init(place: Int?, entry: TeamEntry, isMe: Bool) {
        self.place = place
        self.entry = entry
        self.isMe = isMe
    }
}
