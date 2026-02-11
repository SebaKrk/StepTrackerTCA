//
//  ClaudeAPIService.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 09/02/2026.
//

import Foundation

/// Actor responsible for analyzing workout images via Claude API.
///
/// Used as the cloud-based strategy when on-device Foundation Models
/// are not available on the user's device.
public actor ClaudeAPIService {

    public init() {}

    /// Analyzes a workout image and returns structured workout text.
    /// - Parameter imageData: Raw image data (HEIC, JPEG, PNG).
    /// - Returns: Workout description extracted by Claude.
    public func analyzeWorkoutImage(_ imageData: Data) async throws -> String {
        // TODO: Implement Claude API call with image
        throw ClaudeAPIServiceError.notImplemented
    }
}

// MARK: - Errors

public enum ClaudeAPIServiceError: LocalizedError {
    case notImplemented
    case apiError(String)

    public var errorDescription: String? {
        switch self {
        case .notImplemented:
            String(localized: "AI photo analysis is not yet available.")
        case let .apiError(message):
            message
        }
    }
}
