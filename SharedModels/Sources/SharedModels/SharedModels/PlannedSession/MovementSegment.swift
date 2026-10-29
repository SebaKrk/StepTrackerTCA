//
//  MovementSegment.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation

/// Where a movement sits in a WOD: done once before the rounds, inside every
/// round, or once after them. `nil` on an exercise means `round`.
public enum MovementSegment: String, Codable, Sendable, CaseIterable {
    /// Done once before the rounds start.
    case buyIn

    /// Part of every round.
    case round

    /// Done once after the last round.
    case cashOut
}
