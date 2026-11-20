//
//  SetUnit.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation

/// What a planned set counts: "5 reps", "30 seconds", "200 m", "15 cal".
public enum SetUnit: String, Codable, Sendable, CaseIterable {
    /// Repetitions.
    case reps

    /// Seconds of work, e.g. a 30 s plank.
    case seconds

    /// Meters, e.g. a 200 m run inside a set.
    case meters

    /// Calories on an erg.
    case calories
}
