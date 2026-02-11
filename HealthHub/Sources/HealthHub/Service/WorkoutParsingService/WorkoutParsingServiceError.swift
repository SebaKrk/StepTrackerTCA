//
//  WorkoutParsingServiceError.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 11/02/2026.
//

import Foundation

/// Errors that can occur during workout text parsing with Foundation Models.
public enum WorkoutParsingServiceError: LocalizedError {

    /// Foundation Models are not available on this device.
    case foundationModelsUnavailable

    /// The model failed to generate a valid response.
    case generationFailed

    public var errorDescription: String? {
        switch self {
        case .foundationModelsUnavailable:
            String(localized: "On-device AI is not available on this device.")
        case .generationFailed:
            String(localized: "Failed to parse workout text. Please try again.")
        }
    }
}
