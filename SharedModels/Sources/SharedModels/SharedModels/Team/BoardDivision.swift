//
//  BoardDivision.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 24/10/2026.
//

import Foundation

/// Leaderboard division; Rx and Scaled are ranked separately.
public enum BoardDivision: String, Codable, Sendable, Equatable, CaseIterable {

    /// As prescribed.
    case rx

    /// Scaled weights or movements.
    case scaled
}
