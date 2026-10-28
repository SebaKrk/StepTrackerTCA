//
//  TeamPlan.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 24/10/2026.
//

import Foundation

/// The plan a group trains on a given day.
public struct TeamPlan: Identifiable, Equatable, Codable, Sendable {

    /// Day id (`yyyy-MM-dd`) — one plan per group per day.
    public let id: String

    /// Member who published the plan.
    public let authorUid: String

    /// Name of that member.
    public let authorName: String

    /// Full plan, shown read-only and copied into Plans on download.
    public let session: TrainingSession

    /// Workout blocks whose results the leaderboard shows, in plan order; may be empty.
    public let scoredBlockIds: [UUID]

    /// Effort points window in minutes from each member's start — at least 60.
    public let sessionMinutes: Int

    /// Publication time.
    public let publishedAt: Date

    public init(
        id: String,
        authorUid: String,
        authorName: String,
        session: TrainingSession,
        scoredBlockIds: [UUID],
        sessionMinutes: Int,
        publishedAt: Date
    ) {
        self.id = id
        self.authorUid = authorUid
        self.authorName = authorName
        self.session = session
        self.scoredBlockIds = scoredBlockIds
        self.sessionMinutes = sessionMinutes
        self.publishedAt = publishedAt
    }

    /// Blocks with a result on the leaderboard, in plan order.
    public var scoredBlocks: [WorkoutSessionNew] {
        let ids = Set(scoredBlockIds)
        return session.workouts.filter { ids.contains($0.id) }
    }
}
