//
//  BoardScore.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 24/10/2026.
//

import Foundation

/// A workout score reduced to what a leaderboard can compare.
public enum BoardScore: Codable, Sendable, Equatable {

    /// Finished within the time cap — lower is better.
    case forTime(seconds: Int)

    /// Hit the time cap — fewer remaining reps is better; always below every finisher.
    case capped(capSeconds: Int, remainingReps: Int)

    /// Rounds and extra reps — more is better.
    case amrap(rounds: Int, extraReps: Int)

    /// Heaviest load — more is better.
    case load(kilograms: Double)

    /// Total reps — more is better.
    case reps(Int)

    /// Done, but without a comparable number (completed, custom, EMOM, Tabata).
    case unranked
}
