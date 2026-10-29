//
//  ScannedTargetUnit.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation

/// Unit of a movement's single target ("20 reps", "400 m", "15 cal").
public enum ScannedTargetUnit: String, Codable, Sendable, CaseIterable {
    /// Repetitions.
    case reps

    /// Seconds.
    case seconds

    /// Minutes.
    case minutes

    /// Meters.
    case meters

    /// Kilometers.
    case km

    /// Calories.
    case calories

    /// Laps.
    case laps
}
