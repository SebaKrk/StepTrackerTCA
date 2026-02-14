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

    /// OCR text exceeds Foundation Models context window (4096 tokens).
    case textTooLong

    /// Content violated Foundation Models content policy.
    case contentPolicyViolation

    /// OCR text contains unsupported language (non-English).
    case unsupportedLanguage

    public var errorDescription: String? {
        switch self {
        case .foundationModelsUnavailable:
            String(localized: "On-device AI is not available on this device.")
        case .generationFailed:
            String(localized: "Failed to parse workout text. Please try again.")
        case .textTooLong:
            String(localized: "Workout text is too long to process. Please use a shorter image.")
        case .contentPolicyViolation:
            String(localized: "Workout text contains inappropriate content.")
        case .unsupportedLanguage:
            String(localized: "Detected non-English text. Please ensure workout is in English and avoid capturing UI elements.")
        }
    }
}
