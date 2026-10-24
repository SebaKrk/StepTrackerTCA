//
//  TeamWeekRow.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 24/10/2026.
//

import Foundation

/// One line of the week table.
public struct TeamWeekRow: Identifiable, Equatable, Sendable {

    /// Account id of the member.
    public let uid: String

    /// Name shown in the table.
    public let displayName: String

    /// Place on each day the member was ranked, keyed by day id.
    public let placesByDay: [String: Int]

    /// Days with a plan where the member has no ranked entry.
    public let missingDays: [String]

    /// Sum of places; a missing day counts as that day's last place + 1. Lower is better.
    public let total: Int

    /// Number of days the member was ranked.
    public let workouts: Int

    /// Place in the week from 1.
    public let place: Int

    /// The row belongs to the current user.
    public let isMe: Bool

    public var id: String { uid }

    public init(
        uid: String,
        displayName: String,
        placesByDay: [String: Int],
        missingDays: [String],
        total: Int,
        workouts: Int,
        place: Int,
        isMe: Bool
    ) {
        self.uid = uid
        self.displayName = displayName
        self.placesByDay = placesByDay
        self.missingDays = missingDays
        self.total = total
        self.workouts = workouts
        self.place = place
        self.isMe = isMe
    }
}
