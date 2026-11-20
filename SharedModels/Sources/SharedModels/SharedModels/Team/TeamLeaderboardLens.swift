//
//  TeamLeaderboardLens.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 24/10/2026.
//

import Foundation

/// What the leaderboard ranks by.
public enum TeamLeaderboardLens: Equatable, Sendable, CaseIterable {

    /// Score of the scored block.
    case score

    /// Effort points inside the measurement window.
    case effort
}
