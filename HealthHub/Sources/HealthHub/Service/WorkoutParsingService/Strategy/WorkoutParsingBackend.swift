//
//  WorkoutParsingBackend.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation

/// Selects which backend turns a scan into an ``ExtractedWorkout``.
///
/// Persisted as an app setting so the path can be switched at runtime.
/// Adding a backend = add a case here + a ``WorkoutParsingStrategy`` implementation
/// + extend the switch in ``WorkoutParsingStrategyFactory``.
public enum WorkoutParsingBackend: String, CaseIterable, Sendable, Codable {

    /// Photo → Vision OCR → text → Claude. The original pipeline.
    case claudeText
}
