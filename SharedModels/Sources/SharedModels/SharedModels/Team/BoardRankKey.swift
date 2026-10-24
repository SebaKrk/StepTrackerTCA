//
//  BoardRankKey.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 24/10/2026.
//

import Foundation

/// Sort key that turns every score format into "lower is better".
public struct BoardRankKey: Comparable, Sendable {

    /// Tier of entries that get no place.
    public static let unrankedTier = 2

    /// 0 finished, 1 capped, 2 unranked.
    public let tier: Int

    /// Main measure, already flipped so that lower is better.
    public let primary: Double

    /// Tie-break measure, also lower is better.
    public let secondary: Double

    /// Last resort — the earlier submission wins.
    public let submittedAt: Date

    public init(score: BoardScore, submittedAt: Date) {
        self.submittedAt = submittedAt
        switch score {
        case .forTime(let seconds):
            (tier, primary, secondary) = (0, Double(seconds), 0)
        case .amrap(let rounds, let extraReps):
            (tier, primary, secondary) = (0, -Double(rounds), -Double(extraReps))
        case .load(let kilograms):
            (tier, primary, secondary) = (0, -kilograms, 0)
        case .reps(let reps):
            (tier, primary, secondary) = (0, -Double(reps), 0)
        case .capped(_, let remainingReps):
            (tier, primary, secondary) = (1, Double(remainingReps), 0)
        case .unranked:
            (tier, primary, secondary) = (Self.unrankedTier, 0, 0)
        }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.tier, lhs.primary, lhs.secondary, lhs.submittedAt)
            < (rhs.tier, rhs.primary, rhs.secondary, rhs.submittedAt)
    }
}
