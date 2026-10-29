//
//  WorkoutParsingBackend.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation

/// Selects which backend turns a scan into a ``ScannedBoard``.
///
/// Persisted as an app setting so the path can be switched at runtime.
/// Adding a backend = add a case here + a ``WorkoutParsingStrategy`` implementation
/// + extend the switch in ``WorkoutParsingStrategyFactory``.
public enum WorkoutParsingBackend: String, CaseIterable, Sendable, Codable {

    /// Photo → Vision OCR → text → Claude. The original pipeline.
    case claudeText

    /// Photo only → Claude. The default: on the handwritten board the OCR hint
    /// added tokens and one misread without fixing anything.
    case claudeVision

    /// Photo + OCR transcript as an untrusted hint → Claude. Kept for comparison runs.
    case claudeVisionWithOCRHint
}
