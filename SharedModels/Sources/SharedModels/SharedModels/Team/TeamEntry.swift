//
//  TeamEntry.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 24/10/2026.
//

import Foundation

/// One member's result for a group's daily plan.
public struct TeamEntry: Identifiable, Equatable, Codable, Sendable {

    /// Account id of the member — one entry per member per plan.
    public let uid: String

    /// Name shown on the leaderboard.
    public let displayName: String

    /// Score of the plan's scored block.
    public let score: BoardScore

    /// Rx or Scaled.
    public let division: BoardDivision

    /// Effort points inside the measurement window; `nil` without heart rate.
    public let effortPoints: Int?

    /// `EffortPointsScoring.currentWeightsVersion` that produced `effortPoints`.
    public let weightsVersion: Int?

    /// Active energy inside the window — sent only with the member's consent.
    public let kcal: Double?

    /// Start of the measurement window (the workout start).
    public let windowStart: Date

    /// Minutes of the window covered by heart-rate samples.
    public let measuredMinutes: Int

    /// Heart rate was recorded during the workout.
    public let hrVerified: Bool

    /// Another workout or high activity happened just before the start.
    public let startedAfterActivity: Bool

    /// Submitted on a later day than the plan's day.
    public let isLate: Bool

    /// First submission time.
    public let submittedAt: Date

    /// Time of the last change; `nil` if never edited.
    public let editedAt: Date?

    public var id: String { uid }

    public init(
        uid: String,
        displayName: String,
        score: BoardScore,
        division: BoardDivision,
        effortPoints: Int?,
        weightsVersion: Int?,
        kcal: Double?,
        windowStart: Date,
        measuredMinutes: Int,
        hrVerified: Bool,
        startedAfterActivity: Bool,
        isLate: Bool,
        submittedAt: Date,
        editedAt: Date?
    ) {
        self.uid = uid
        self.displayName = displayName
        self.score = score
        self.division = division
        self.effortPoints = effortPoints
        self.weightsVersion = weightsVersion
        self.kcal = kcal
        self.windowStart = windowStart
        self.measuredMinutes = measuredMinutes
        self.hrVerified = hrVerified
        self.startedAfterActivity = startedAfterActivity
        self.isLate = isLate
        self.submittedAt = submittedAt
        self.editedAt = editedAt
    }
}
