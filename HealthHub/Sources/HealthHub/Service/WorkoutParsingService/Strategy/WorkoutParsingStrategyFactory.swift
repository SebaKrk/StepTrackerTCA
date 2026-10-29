//
//  WorkoutParsingStrategyFactory.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation

/// Builds the ``WorkoutParsingStrategy`` for a chosen ``WorkoutParsingBackend``.
///
/// The only place that knows which concrete strategy backs each case,
/// so the feature layer depends on the enum and the protocol alone.
public enum WorkoutParsingStrategyFactory {

    /// - Parameter apiKey: Claude API key for cloud backends; ignored by on-device ones.
    public static func make(
        _ backend: WorkoutParsingBackend,
        apiKey: String?
    ) -> any WorkoutParsingStrategy {
        switch backend {
        case .claudeText:
            return ClaudeStrategy(apiKey: apiKey)
        case .claudeVision:
            return ClaudeVisionStrategy(apiKey: apiKey, includesOCRHint: false)
        case .claudeVisionWithOCRHint:
            return ClaudeVisionStrategy(apiKey: apiKey, includesOCRHint: true)
        }
    }
}
