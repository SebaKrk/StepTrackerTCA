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

    /// Sum of comparable effort points this week. Higher is better.
    public let points: Int

    /// Sum of shared kcal this week; `nil` when the member shared none.
    public let kcal: Int?

    /// Number of workouts submitted this week.
    public let workouts: Int

    /// Place in the week from 1.
    public let place: Int

    /// The row belongs to the current user.
    public let isMe: Bool

    public var id: String { uid }

    public init(
        uid: String,
        displayName: String,
        points: Int,
        kcal: Int?,
        workouts: Int,
        place: Int,
        isMe: Bool
    ) {
        self.uid = uid
        self.displayName = displayName
        self.points = points
        self.kcal = kcal
        self.workouts = workouts
        self.place = place
        self.isMe = isMe
    }
}
