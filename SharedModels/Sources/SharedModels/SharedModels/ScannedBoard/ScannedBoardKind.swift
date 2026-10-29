//
//  ScannedBoardKind.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation

/// What the model saw: the routing hint for validators, never a plan field.
public enum ScannedBoardKind: String, Codable, Sendable, CaseIterable {
    /// Only set work.
    case strengthDay

    /// Only timed blocks.
    case wodDay

    /// Set work and timed blocks together.
    case mixed

    /// The photo shows no training plan.
    case notAWorkout
}
